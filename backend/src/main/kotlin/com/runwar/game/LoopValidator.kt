package com.runwar.game

import com.runwar.config.GameProperties
import org.springframework.stereotype.Service
import java.time.Duration
import java.time.Instant

@Service
class LoopValidator(
    private val gameProperties: GameProperties,
    private val h3GridService: H3GridService,
    private val antiFraudService: AntiFraudService
) {
    
    data class ValidationResult(
        val isValid: Boolean,
        val distance: Double, // total distance in meters
        val duration: Int, // duration in seconds
        val closingDistance: Double, // distance between start and end
        val tilesCovered: List<String>,
        val primaryTile: String?,
        val primaryTileCoverage: Double,
        val fraudFlags: List<String>,
        val failureReasons: List<String>
    ) {
        companion object {
            fun invalid(reason: String) = ValidationResult(
                isValid = false,
                distance = 0.0,
                duration = 0,
                closingDistance = 0.0,
                tilesCovered = emptyList(),
                primaryTile = null,
                primaryTileCoverage = 0.0,
                fraudFlags = emptyList(),
                failureReasons = listOf(reason)
            )
        }
    }
    
    /**
     * Validate a run to determine if it forms a valid loop for territory action
     */
    fun validate(
        coordinates: List<LatLngPoint>,
        timestamps: List<Instant>
    ): ValidationResult {
        if (coordinates.size < 2) {
            return ValidationResult.invalid("not_enough_points")
        }
        
        if (coordinates.size != timestamps.size) {
            return ValidationResult.invalid("mismatched_coordinates_timestamps")
        }
        
        val failureReasons = mutableListOf<String>()
        
        // Calculate total distance
        val totalDistance = calculateTotalDistance(coordinates)
        
        // Calculate duration
        val totalDuration = Duration.between(timestamps.first(), timestamps.last()).seconds.toInt()
        
        // Calculate closing distance (loop check)
        val closingDistance = H3GridService.haversineDistance(
            coordinates.first(),
            coordinates.last()
        )
        
        // Get tiles covered and their coverage percentages
        val tileCoverage = h3GridService.calculateTileCoverage(coordinates)
        val tilesCovered = tileCoverage.keys.toList()
        
        // Find primary tile (highest coverage)
        val primaryTileEntry = tileCoverage.maxByOrNull { it.value }
        val primaryTile = primaryTileEntry?.key
        val primaryCoverage = primaryTileEntry?.value ?: 0.0
        
        // Run anti-fraud checks
        val fraudFlags = antiFraudService.detectFraud(coordinates, timestamps)
        
        // Check all validation criteria
        if (totalDistance < gameProperties.minLoopDistance) {
            failureReasons.add("distance_too_short")
        }
        
        if (totalDuration < gameProperties.minLoopDuration) {
            failureReasons.add("duration_too_short")
        }
        
        if (closingDistance > gameProperties.maxClosingDistance) {
            failureReasons.add("loop_not_closed")
        }
        
        if (primaryCoverage < gameProperties.minTileCoverage) {
            failureReasons.add("insufficient_tile_coverage")
        }
        
        if (fraudFlags.isNotEmpty()) {
            failureReasons.add("fraud_detected")
        }
        
        // Check if primary tile is within Curitiba
        if (primaryTile != null) {
            val center = h3GridService.getTileCenter(primaryTile)
            if (!h3GridService.isInCuritiba(center.lat, center.lng)) {
                failureReasons.add("outside_game_area")
            }
        }
        
        val isValid = failureReasons.isEmpty()
        
        return ValidationResult(
            isValid = isValid,
            distance = totalDistance,
            duration = totalDuration,
            closingDistance = closingDistance,
            tilesCovered = tilesCovered,
            primaryTile = primaryTile,
            primaryTileCoverage = primaryCoverage,
            fraudFlags = fraudFlags,
            failureReasons = failureReasons
        )
    }
    
    private fun calculateTotalDistance(coordinates: List<LatLngPoint>): Double {
        var total = 0.0
        for (i in 0 until coordinates.size - 1) {
            total += H3GridService.haversineDistance(coordinates[i], coordinates[i + 1])
        }
        return total
    }
}
