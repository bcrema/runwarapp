package com.runwar.game

data class LoopValidationFlags(
    val minLoopDistanceKm: Double = 1.2,
    val minLoopDurationMin: Int = 7,
    val maxClosureMeters: Double = 40.0,
    val minCoveragePct: Double = 0.60
)

data class LoopValidationMetrics(
    val loopDistanceMeters: Double,
    val loopDurationSeconds: Int,
    val closureMeters: Double,
    val coveragePct: Double
)

data class LoopValidationInput(
    val coordinates: List<LatLngPoint>,
    val timestamps: List<java.time.Instant>
)

