package com.runwar.game

import com.runwar.config.GameProperties
import org.springframework.stereotype.Service
import java.time.Duration
import java.time.Instant

@Service
class AntiFraudService(private val gameProperties: GameProperties) {
    
    companion object {
        const val TELEPORT_THRESHOLD_METERS = 500.0 // Max distance between consecutive points
        const val MIN_POINT_INTERVAL_SECONDS = 1L   // Minimum expected interval
        const val GPS_ACCURACY_THRESHOLD = 50.0     // meters, considered poor accuracy
    }
    
    /**
     * Detect potential fraud indicators in a run
     * Returns empty list if no fraud detected
     */
    fun detectFraud(
        coordinates: List<LatLngPoint>,
        timestamps: List<Instant>
    ): List<String> {
        val flags = mutableListOf<String>()
        
        // Check for sustained high speed
        val speedViolation = detectHighSpeed(coordinates, timestamps)
        if (speedViolation != null) {
            flags.add(speedViolation)
        }
        
        // Check for teleports (sudden location jumps)
        val teleportViolation = detectTeleports(coordinates, timestamps)
        if (teleportViolation != null) {
            flags.add(teleportViolation)
        }
        
        // Check for unrealistic point density
        val densityViolation = detectUnrealisticDensity(coordinates, timestamps)
        if (densityViolation != null) {
            flags.add(densityViolation)
        }
        
        return flags
    }
    
    /**
     * Detect sustained high-speed movement indicating vehicle or GPS spoofing
     */
    private fun detectHighSpeed(
        coordinates: List<LatLngPoint>,
        timestamps: List<Instant>
    ): String? {
        if (coordinates.size < 2) return null
        
        val maxSpeedMps = gameProperties.maxSpeedKmh * 1000.0 / 3600.0 // Convert to m/s
        val maxDuration = gameProperties.maxSpeedDurationSeconds
        
        var highSpeedDuration = 0L
        var highSpeedStartIndex = -1
        
        for (i in 0 until coordinates.size - 1) {
            val distance = H3GridService.haversineDistance(coordinates[i], coordinates[i + 1])
            val duration = Duration.between(timestamps[i], timestamps[i + 1]).seconds
            
            if (duration <= 0) continue
            
            val speed = distance / duration
            
            if (speed > maxSpeedMps) {
                if (highSpeedStartIndex == -1) {
                    highSpeedStartIndex = i
                }
                highSpeedDuration += duration
                
                if (highSpeedDuration >= maxDuration) {
                    return "high_speed_sustained_${String.format("%.1f", speed * 3600 / 1000)}kmh"
                }
            } else {
                highSpeedDuration = 0
                highSpeedStartIndex = -1
            }
        }
        
        return null
    }
    
    /**
     * Detect sudden teleportation (GPS spoofing indicator)
     */
    private fun detectTeleports(
        coordinates: List<LatLngPoint>,
        timestamps: List<Instant>
    ): String? {
        if (coordinates.size < 2) return null
        
        for (i in 0 until coordinates.size - 1) {
            val distance = H3GridService.haversineDistance(coordinates[i], coordinates[i + 1])
            val duration = Duration.between(timestamps[i], timestamps[i + 1]).seconds
            
            // If two points are very close in time but far apart, it's a teleport
            if (duration <= 2 && distance > TELEPORT_THRESHOLD_METERS) {
                return "teleport_detected_${distance.toInt()}m"
            }
        }
        
        return null
    }
    
    /**
     * Detect unrealistic GPS point patterns
     */
    private fun detectUnrealisticDensity(
        coordinates: List<LatLngPoint>,
        timestamps: List<Instant>
    ): String? {
        if (timestamps.size < 2) return null
        
        val totalDuration = Duration.between(timestamps.first(), timestamps.last()).seconds
        
        // Too many points in short time (fake data injection)
        val pointsPerSecond = coordinates.size.toDouble() / maxOf(1, totalDuration).toDouble()
        if (pointsPerSecond > 5) {
            return "unrealistic_point_density"
        }
        
        // Too few points for duration (interpolated fake data)
        if (totalDuration > 300 && pointsPerSecond < 0.05) {
            return "sparse_data_points"
        }
        
        return null
    }
    
    /**
     * Check if a run has minor quality issues (valid for training, not territory)
     * These don't count as fraud, just poor data quality
     */
    fun hasQualityIssues(
        coordinates: List<LatLngPoint>,
        timestamps: List<Instant>
    ): List<String> {
        val issues = mutableListOf<String>()
        
        // Check for too many stationary points
        var stationaryCount = 0
        for (i in 0 until coordinates.size - 1) {
            val distance = H3GridService.haversineDistance(coordinates[i], coordinates[i + 1])
            if (distance < 1.0) {
                stationaryCount++
            }
        }
        
        val stationaryRatio = stationaryCount.toDouble() / coordinates.size
        if (stationaryRatio > 0.3) {
            issues.add("high_stationary_ratio")
        }
        
        // Check for large gaps in timestamps
        for (i in 0 until timestamps.size - 1) {
            val gap = Duration.between(timestamps[i], timestamps[i + 1]).seconds
            if (gap > 60) {
                issues.add("timestamp_gap_${gap}s")
                break // Only report first
            }
        }
        
        return issues
    }
}
