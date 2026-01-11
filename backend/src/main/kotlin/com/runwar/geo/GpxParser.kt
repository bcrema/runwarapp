package com.runwar.geo

import com.runwar.game.LatLngPoint
import io.jenetics.jpx.GPX
import io.jenetics.jpx.TrackSegment
import org.springframework.stereotype.Service
import org.springframework.web.multipart.MultipartFile
import java.io.InputStream
import java.time.Instant

@Service
class GpxParser {
    
    data class ParsedTrack(
        val coordinates: List<LatLngPoint>,
        val timestamps: List<Instant>,
        val totalDistance: Double,
        val totalDuration: Int,
        val startTime: Instant,
        val endTime: Instant
    )
    
    /**
     * Parse a GPX file into coordinates and timestamps
     */
    fun parse(file: MultipartFile): ParsedTrack {
        return parse(file.inputStream)
    }
    
    fun parse(inputStream: InputStream): ParsedTrack {
        val gpx = GPX.Reader.of(GPX.Reader.Mode.LENIENT).read(inputStream)
        
        val coordinates = mutableListOf<LatLngPoint>()
        val timestamps = mutableListOf<Instant>()
        
        // Extract all track points
        gpx.tracks().forEach { track ->
            track.segments().forEach { segment: TrackSegment ->
                segment.points().forEach { point ->
                    coordinates.add(LatLngPoint(
                        lat = point.latitude.toDouble(),
                        lng = point.longitude.toDouble()
                    ))
                    
                    // Get timestamp or estimate
                    val time = point.time.orElse(null)
                    if (time != null) {
                        timestamps.add(Instant.from(time))
                    } else if (timestamps.isNotEmpty()) {
                        // Estimate timestamp based on previous
                        timestamps.add(timestamps.last().plusSeconds(1))
                    } else {
                        timestamps.add(Instant.now())
                    }
                }
            }
        }
        
        if (coordinates.isEmpty()) {
            throw IllegalArgumentException("GPX file contains no track points")
        }
        
        val totalDistance = calculateTotalDistance(coordinates)
        val startTime = timestamps.first()
        val endTime = timestamps.last()
        val totalDuration = java.time.Duration.between(startTime, endTime).seconds.toInt()
        
        return ParsedTrack(
            coordinates = coordinates,
            timestamps = timestamps,
            totalDistance = totalDistance,
            totalDuration = totalDuration,
            startTime = startTime,
            endTime = endTime
        )
    }
    
    private fun calculateTotalDistance(coordinates: List<LatLngPoint>): Double {
        var total = 0.0
        for (i in 0 until coordinates.size - 1) {
            total += haversineDistance(coordinates[i], coordinates[i + 1])
        }
        return total
    }
    
    private fun haversineDistance(p1: LatLngPoint, p2: LatLngPoint): Double {
        val R = 6371000.0
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
