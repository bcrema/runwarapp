package com.runwar.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "runwar.game")
data class GameProperties(
    // Loop validation
    val minLoopDistance: Double = 1200.0,
    val minLoopDuration: Int = 420,
    val maxClosingDistance: Double = 40.0,
    val minTileCoverage: Double = 0.6,
    
    // Shield mechanics
    val conquestInitialShield: Int = 100,
    val attackDamage: Int = 35,
    val defenseHeal: Int = 20,
    val maxShield: Int = 100,
    val transferShield: Int = 65,
    val cooldownHours: Long = 18,
    val disputeThreshold: Int = 70,
    val decayStartDays: Int = 10,
    val decayPerDay: Int = 10,
    val decayMinimum: Int = 30,
    
    // Action caps
    val userDailyActionCap: Int = 3,
    val bandeiraDailyActionCap: Int = 60,
    
    // Anti-fraud
    val maxSpeedKmh: Double = 25.0,
    val maxSpeedDurationSeconds: Int = 30,
    
    // H3 Grid
    val h3Resolution: Int? = null,
    val h3TargetRadiusMeters: Double = 250.0,
    
    // Curitiba bounds
    val curitiba: CuritibaBounds = CuritibaBounds()
)

data class CuritibaBounds(
    val minLat: Double = -25.65,
    val maxLat: Double = -25.35,
    val minLng: Double = -49.40,
    val maxLng: Double = -49.15
)
