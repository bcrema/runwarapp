package com.runwar.game

import com.runwar.config.GameProperties
import com.uber.h3core.H3Core
import com.uber.h3core.util.LatLng
import org.locationtech.jts.geom.Coordinate
import org.locationtech.jts.geom.Geometry
import org.locationtech.jts.geom.GeometryCollection
import org.locationtech.jts.geom.GeometryFactory
import org.locationtech.jts.geom.LineString
import org.locationtech.jts.geom.MultiLineString
import org.locationtech.jts.geom.Point
import org.locationtech.jts.geom.Polygon
import org.locationtech.jts.geom.PrecisionModel
import org.springframework.stereotype.Service
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.pow
import kotlin.math.sqrt

@Service
class H3GridService(private val gameProperties: GameProperties) {
    
    private val h3: H3Core = H3Core.newInstance()
    private val geometryFactory = GeometryFactory(PrecisionModel(), 4326)
    
    val resolution: Int = gameProperties.h3Resolution
        ?: chooseResolutionForRadius(gameProperties.h3TargetRadiusMeters)
    
    /**
     * Get H3 cell ID for a coordinate
     */
    fun getTileId(lat: Double, lng: Double): String {
        return h3.latLngToCellAddress(lat, lng, resolution)
    }
    
    /**
     * Get all tile IDs covered by a polyline
     */
    fun getTilesForPolyline(coordinates: List<LatLngPoint>): List<String> {
        return coordinates
            .map { getTileId(it.lat, it.lng) }
            .distinct()
    }
    
    /**
     * Get the center point of a tile
     */
    fun getTileCenter(quadraId: String): LatLngPoint {
        val center = h3.cellToLatLng(quadraId)
        return LatLngPoint(center.lat, center.lng)
    }
    
    /**
     * Get the center as a JTS Point
     */
    fun getTileCenterAsPoint(quadraId: String): Point {
        val center = getTileCenter(quadraId)
        return geometryFactory.createPoint(Coordinate(center.lng, center.lat))
    }
    
    /**
     * Get the boundary vertices of a tile (hexagon)
     */
    fun getTileBoundary(quadraId: String): List<LatLngPoint> {
        return h3.cellToBoundary(quadraId).map { LatLngPoint(it.lat, it.lng) }
    }

    /**
     * Resolve a tile index and polygon for a coordinate (map overlay).
     */
    fun getTileOverlay(lat: Double, lng: Double): TileOverlay {
        val quadraId = getTileId(lat, lng)
        return TileOverlay(quadraId = quadraId, boundary = getTileBoundary(quadraId))
    }
    
    /**
     * Get neighboring tiles (k=1 ring)
     */
    fun getNeighbors(quadraId: String): List<String> {
        return h3.gridDisk(quadraId, 1).filter { it != quadraId }
    }
    
    /**
     * Check if two tiles are adjacent
     */
    fun areAdjacent(tileId1: String, tileId2: String): Boolean {
        return h3.gridDistance(tileId1, tileId2) == 1L
    }
    
    /**
     * Get all tiles in Curitiba bounds
     */
    fun getAllTilesInCuritiba(): List<String> {
        val bounds = gameProperties.curitiba
        val polygon = listOf(
            LatLng(bounds.minLat, bounds.minLng),
            LatLng(bounds.maxLat, bounds.minLng),
            LatLng(bounds.maxLat, bounds.maxLng),
            LatLng(bounds.minLat, bounds.maxLng),
            LatLng(bounds.minLat, bounds.minLng) // close the polygon
        )
        return h3.polygonToCellAddresses(polygon, emptyList(), resolution)
    }
    
    /**
     * Check if a coordinate is within Curitiba bounds
     */
    fun isInCuritiba(lat: Double, lng: Double): Boolean {
        val bounds = gameProperties.curitiba
        return lat >= bounds.minLat && lat <= bounds.maxLat &&
               lng >= bounds.minLng && lng <= bounds.maxLng
    }
    
    /**
     * Calculate what percentage of a route is within each tile
     */
    fun calculateTileCoverage(coordinates: List<LatLngPoint>): Map<String, Double> {
        if (coordinates.size < 2) return emptyMap()
        
        val segmentsByTile = mutableMapOf<String, Double>()
        var totalDistance = 0.0
        
        for (i in 0 until coordinates.size - 1) {
            val p1 = coordinates[i]
            val p2 = coordinates[i + 1]
            val segmentDistance = haversineDistance(p1, p2)
            if (abs(segmentDistance) < 1e-9) {
                continue
            }
            totalDistance += segmentDistance

            val line = geometryFactory.createLineString(
                arrayOf(
                    Coordinate(p1.lng, p1.lat),
                    Coordinate(p2.lng, p2.lat)
                )
            )

            val candidateTiles = getCandidateTilesForSegment(p1, p2, segmentDistance)
            candidateTiles.forEach { quadraId ->
                val polygon = getTilePolygon(quadraId)
                val distanceInTile = intersectionDistanceMeters(line, polygon)
                if (distanceInTile > 0) {
                    segmentsByTile[quadraId] = (segmentsByTile[quadraId] ?: 0.0) + distanceInTile
                }
            }
        }
        
        // Convert to percentages
        return if (totalDistance > 0) {
            segmentsByTile.mapValues { it.value / totalDistance }
        } else {
            emptyMap()
        }
    }

    /**
     * Determine the primary tile (highest coverage) and its overlay boundary for a track.
     */
    fun getPrimaryTileForTrack(coordinates: List<LatLngPoint>): TileCoverageResult? {
        val coverage = calculateTileCoverage(coordinates)
        val primary = coverage.maxByOrNull { it.value } ?: return null
        return TileCoverageResult(
            quadraId = primary.key,
            coverage = primary.value,
            boundary = getTileBoundary(primary.key)
        )
    }
    
    /**
     * Find connected clusters of tiles owned by the same entity
     */
    fun findConnectedClusters(tileIds: List<String>): List<List<String>> {
        if (tileIds.isEmpty()) return emptyList()
        
        val remaining = tileIds.toMutableSet()
        val clusters = mutableListOf<List<String>>()
        
        while (remaining.isNotEmpty()) {
            val start = remaining.first()
            val cluster = mutableListOf<String>()
            val queue = ArrayDeque<String>()
            queue.add(start)
            
            while (queue.isNotEmpty()) {
                val current = queue.removeFirst()
                if (current in remaining) {
                    remaining.remove(current)
                    cluster.add(current)
                    
                    getNeighbors(current)
                        .filter { it in remaining }
                        .forEach { queue.add(it) }
                }
            }
            
            clusters.add(cluster)
        }
        
        return clusters
    }

    private fun chooseResolutionForRadius(targetRadiusMeters: Double): Int {
        val baseEdgeLengthMeters = 1_107_712.591
        val edgeLengthRatio = sqrt(7.0)
        val candidates = 0..15
        return candidates.minByOrNull { resolution ->
            val edgeLengthMeters = baseEdgeLengthMeters / edgeLengthRatio.pow(resolution.toDouble())
            val approxRadiusMeters = edgeLengthMeters / 2.0
            abs(approxRadiusMeters - targetRadiusMeters)
        } ?: 8
    }

    private fun getCandidateTilesForSegment(
        start: LatLngPoint,
        end: LatLngPoint,
        segmentDistanceMeters: Double
    ): Set<String> {
        val steps = maxOf(1, ceil(segmentDistanceMeters / segmentSampleIntervalMetersForResolution(resolution)).toInt())
        return (0..steps)
            .mapTo(mutableSetOf()) { step ->
                val ratio = step.toDouble() / steps
                val lat = start.lat + (end.lat - start.lat) * ratio
                val lng = start.lng + (end.lng - start.lng) * ratio
                getTileId(lat, lng)
            }
    }

    private fun getTilePolygon(quadraId: String): Polygon {
        val boundary = h3.cellToBoundary(quadraId)
        require(boundary.isNotEmpty()) {
            "Invalid H3 tile ID '$quadraId': cellToBoundary returned an empty boundary."
        }
        val coordinates = boundary.map { Coordinate(it.lng, it.lat) }.toMutableList()
        coordinates.add(coordinates.first())
        return geometryFactory.createPolygon(coordinates.toTypedArray())
    }

    private fun intersectionDistanceMeters(line: LineString, polygon: Polygon): Double {
        val intersection = line.intersection(polygon)
        val lineStrings = mutableListOf<LineString>()
        collectLineStrings(intersection, lineStrings)
        return lineStrings.sumOf { lineStringDistanceMeters(it) }
    }

    private fun collectLineStrings(geometry: Geometry, collector: MutableList<LineString>) {
        when (geometry) {
            is LineString -> collector.add(geometry)
            is MultiLineString,
            is GeometryCollection -> {
                for (index in 0 until geometry.numGeometries) {
                    collectLineStrings(geometry.getGeometryN(index), collector)
                }
            }
        }
    }

    private fun lineStringDistanceMeters(line: LineString): Double {
        val coords = line.coordinates
        if (coords.size < 2) return 0.0
        var total = 0.0
        for (i in 0 until coords.size - 1) {
            val p1 = LatLngPoint(coords[i].y, coords[i].x)
            val p2 = LatLngPoint(coords[i + 1].y, coords[i + 1].x)
            total += haversineDistance(p1, p2)
        }
        return total
    }
    
    companion object {
        /**
         * Reference H3 resolution for which the base sampling interval is defined.
         * Resolution 8 corresponds roughly to ~250m radius tiles; the existing 50m
         * interval was tuned for this resolution.
         */
        private const val BASE_H3_RESOLUTION = 8

        /**
         * Base segment sampling interval in meters for [BASE_H3_RESOLUTION].
         *
         * For backward compatibility, this preserves the original behavior of
         * sampling every 50 meters at resolution 8.
         */
        private const val BASE_SEGMENT_SAMPLE_INTERVAL_METERS = 50.0

        /**
         * Compute an appropriate segment sampling interval (in meters) for a given
         * H3 resolution.
         *
         * As resolution increases, H3 cell sizes shrink. We adjust the sampling
         * interval exponentially so that higher resolutions use a finer sampling
         * and lower resolutions use a coarser sampling, while keeping the interval
         * at [BASE_SEGMENT_SAMPLE_INTERVAL_METERS] for [BASE_H3_RESOLUTION].
         */
        fun segmentSampleIntervalMetersForResolution(resolution: Int): Double {
            val resolutionDelta = resolution - BASE_H3_RESOLUTION
            val scaleFactor = 2.0.pow(resolutionDelta.toDouble())
            // For resolution > BASE_H3_RESOLUTION, this yields a smaller interval;
            // for resolution < BASE_H3_RESOLUTION, a larger interval.
            return BASE_SEGMENT_SAMPLE_INTERVAL_METERS / scaleFactor
        }

        /**
         * Calculate distance between two points using Haversine formula
         */
        fun haversineDistance(p1: LatLngPoint, p2: LatLngPoint): Double {
            val R = 6371000.0 // Earth radius in meters
            
            val lat1 = Math.toRadians(p1.lat)
            val lat2 = Math.toRadians(p2.lat)
            val deltaLat = Math.toRadians(p2.lat - p1.lat)
            val deltaLng = Math.toRadians(p2.lng - p1.lng)
            
            val a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
                    Math.cos(lat1) * Math.cos(lat2) *
                    Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2)
            
            val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
            
            return R * c
        }
    }
}

data class LatLngPoint(
    val lat: Double,
    val lng: Double
)

data class TileOverlay(
    val quadraId: String,
    val boundary: List<LatLngPoint>
)

data class TileCoverageResult(
    val quadraId: String,
    val coverage: Double,
    val boundary: List<LatLngPoint>
)
