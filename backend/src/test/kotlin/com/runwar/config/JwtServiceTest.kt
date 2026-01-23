package com.runwar.config

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import java.util.UUID

class JwtServiceTest {

    private val jwtProperties = JwtProperties(
        secret = "01234567890123456789012345678901",
        expiration = 60_000,
        refreshExpiration = 3_600_000
    )

    @Test
    fun `generateToken creates a token that can be parsed`() {
        val service = JwtService(jwtProperties)
        val userId = UUID.randomUUID()
        val email = "user@example.com"

        val token = service.generateToken(userId, email)

        assertEquals(userId, service.extractUserId(token))
        assertEquals(email, service.extractEmail(token))
        assertTrue(service.isTokenValid(token))
    }

    @Test
    fun `expired token is considered invalid`() {
        val expiredService = JwtService(
            jwtProperties.copy(expiration = -60_000)
        )

        val token = expiredService.generateToken(UUID.randomUUID(), "user@example.com")

        assertFalse(expiredService.isTokenValid(token))
        assertNull(expiredService.extractUserId(token))
        assertNull(expiredService.extractEmail(token))
    }

    @Test
    fun `invalid token returns null claims and is invalid`() {
        val service = JwtService(jwtProperties)

        assertNull(service.extractUserId("not-a-jwt"))
        assertNull(service.extractEmail("not-a-jwt"))
        assertFalse(service.isTokenValid("not-a-jwt"))
    }
}

