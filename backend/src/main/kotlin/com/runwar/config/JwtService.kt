package com.runwar.config

import io.jsonwebtoken.Claims
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.stereotype.Service
import java.util.*
import javax.crypto.SecretKey

@Service
class JwtService(private val jwtProperties: JwtProperties) {
    
    private val secretKey: SecretKey by lazy {
        Keys.hmacShaKeyFor(jwtProperties.secret.toByteArray())
    }
    
    fun generateToken(userId: UUID, email: String): String {
        return Jwts.builder()
            .subject(userId.toString())
            .claim("email", email)
            .issuedAt(Date())
            .expiration(Date(System.currentTimeMillis() + jwtProperties.expiration))
            .signWith(secretKey)
            .compact()
    }
    
    fun extractUserId(token: String): UUID? {
        return try {
            val subject = extractAllClaims(token).subject
            UUID.fromString(subject)
        } catch (e: Exception) {
            null
        }
    }
    
    fun extractEmail(token: String): String? {
        return try {
            extractAllClaims(token)["email"] as? String
        } catch (e: Exception) {
            null
        }
    }
    
    fun isTokenValid(token: String): Boolean {
        return try {
            val claims = extractAllClaims(token)
            !claims.expiration.before(Date())
        } catch (e: Exception) {
            false
        }
    }
    
    private fun extractAllClaims(token: String): Claims {
        return Jwts.parser()
            .verifyWith(secretKey)
            .build()
            .parseSignedClaims(token)
            .payload
    }
}
