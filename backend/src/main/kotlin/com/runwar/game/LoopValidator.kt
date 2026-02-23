package com.runwar.game

import org.springframework.stereotype.Service
import java.time.Duration

@Service
class LoopValidator(
    private val h3GridService: H3GridService,
    private val antiFraudService: AntiFraudService
) {
    
    data class ValidationResult(
        val isLoopValid: Boolean,
        val reasons: List<String>,
        val metrics: LoopValidationMetrics,
        val quadrasCovered: List<String>,
        val primaryQuadra: String?,
        val fraudFlags: List<String>
    ) {
        companion object {
            fun invalid(reason: String) = ValidationResult(
                isLoopValid = false,
                reasons = listOf(reason),
                metrics = LoopValidationMetrics(
                    loopDistanceMeters = 0.0,
                    loopDurationSeconds = 0,
                    closureMeters = 0.0,
                    coveragePct = 0.0
                ),
                quadrasCovered = emptyList(),
                primaryQuadra = null,
                fraudFlags = emptyList()
            )
        }
    }
    
    /**
     * Validate a run to determine if it forms a valid loop for territory action
     */
    fun validate(
        run: LoopValidationInput,
        flags: LoopValidationFlags
    ): ValidationResult {
        val coordinates = run.coordinates
        val timestamps = run.timestamps

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
        val quadrasCovered = tileCoverage.keys.toList()
        
        // Find primary tile (highest coverage)
        val primaryTileEntry = tileCoverage.maxByOrNull { it.value }
        val primaryQuadra = primaryTileEntry?.key
        val primaryCoverage = primaryTileEntry?.value ?: 0.0
        
        // Run anti-fraud checks
        val fraudFlags = antiFraudService.detectFraud(coordinates, timestamps)
        
        // Check all validation criteria
        if (totalDistance < flags.minLoopDistanceKm * 1000) {
            failureReasons.add("distance_too_short")
        }
        
        if (totalDuration < flags.minLoopDurationMin * 60) {
            failureReasons.add("duration_too_short")
        }
        
        if (closingDistance > flags.maxClosureMeters) {
            failureReasons.add("loop_not_closed")
        }
        
        if (primaryCoverage < flags.minCoveragePct) {
            failureReasons.add("insufficient_quadra_coverage")
        }
        
        if (fraudFlags.isNotEmpty()) {
            failureReasons.add("fraud_detected")
        }
        
        // Check if primary tile is within Curitiba
        if (primaryQuadra != null) {
            val center = h3GridService.getTileCenter(primaryQuadra)
            if (!h3GridService.isInCuritiba(center.lat, center.lng)) {
                failureReasons.add("outside_game_area")
            }
        }
        
        val isValid = failureReasons.isEmpty()
        
        return ValidationResult(
            isLoopValid = isValid,
            reasons = failureReasons,
            metrics = LoopValidationMetrics(
                loopDistanceMeters = totalDistance,
                loopDurationSeconds = totalDuration,
                closureMeters = closingDistance,
                coveragePct = primaryCoverage
            ),
            quadrasCovered = quadrasCovered,
            primaryQuadra = primaryQuadra,
            fraudFlags = fraudFlags
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
