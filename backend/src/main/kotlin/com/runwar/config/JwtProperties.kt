package com.runwar.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "jwt")
data class JwtProperties(
    val secret: String = "",
    val expiration: Long = 900000, // 15 minutes
    val refreshExpiration: Long = 2592000000 // 30 days
)
