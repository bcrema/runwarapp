package com.runwar.game

import com.runwar.config.GameProperties
import com.uber.h3core.H3Core
import com.uber.h3core.util.LatLng
import org.locationtech.jts.geom.Coordinate
import org.locationtech.jts.geom.GeometryFactory
import org.locationtech.jts.geom.Point
import org.locationtech.jts.geom.PrecisionModel
import org.springframework.stereotype.Service

@Service
class H3GridService(private val gameProperties: GameProperties) {
    
    private val h3: H3Core = H3Core.newInstance()
    private val geometryFactory = GeometryFactory(PrecisionModel(), 4326)
    
    val resolution: Int get() = gameProperties.h3Resolution
    
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
    fun getTileCenter(tileId: String): LatLngPoint {
        val center = h3.cellToLatLng(tileId)
        return LatLngPoint(center.lat, center.lng)
    }
    
    /**
     * Get the center as a JTS Point
     */
    fun getTileCenterAsPoint(tileId: String): Point {
        val center = getTileCenter(tileId)
        return geometryFactory.createPoint(Coordinate(center.lng, center.lat))
    }
    
    /**
     * Get the boundary vertices of a tile (hexagon)
     */
    fun getTileBoundary(tileId: String): List<LatLngPoint> {
        return h3.cellToBoundary(tileId).map { LatLngPoint(it.lat, it.lng) }
    }
    
    /**
     * Get neighboring tiles (k=1 ring)
     */
    fun getNeighbors(tileId: String): List<String> {
        return h3.gridDisk(tileId, 1).filter { it != tileId }
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
            totalDistance += segmentDistance
            
            // Attribute segment to midpoint tile
            val midLat = (p1.lat + p2.lat) / 2
            val midLng = (p1.lng + p2.lng) / 2
            val tileId = getTileId(midLat, midLng)
            
            segmentsByTile[tileId] = (segmentsByTile[tileId] ?: 0.0) + segmentDistance
        }
        
        // Convert to percentages
        return if (totalDistance > 0) {
            segmentsByTile.mapValues { it.value / totalDistance }
        } else {
            emptyMap()
        }
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
    
    companion object {
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
