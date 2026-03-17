package com.runwar.domain.user

import com.runwar.config.JwtProperties
import com.runwar.config.UnauthorizedException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import java.util.Date
import javax.crypto.SecretKey
import org.springframework.stereotype.Service

@Service
class SocialLinkTokenService(
    private val jwtProperties: JwtProperties
) {
    private val secretKey: SecretKey by lazy {
        Keys.hmacShaKeyFor(jwtProperties.secret.toByteArray())
    }

    fun generate(payload: PendingSocialLink): String {
        return Jwts.builder()
            .subject(payload.providerSubject)
            .claim("tokenType", TOKEN_TYPE)
            .claim("provider", payload.provider.apiValue)
            .claim("email", payload.email)
            .claim("displayName", payload.displayName)
            .claim("avatarUrl", payload.avatarUrl)
            .issuedAt(Date())
            .expiration(Date(System.currentTimeMillis() + jwtProperties.socialLinkExpiration))
            .signWith(secretKey)
            .compact()
    }

    fun parse(token: String): PendingSocialLink {
        val claims = try {
            Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .payload
        } catch (e: Exception) {
            throw UnauthorizedException("Invalid link token")
        }

        if (claims["tokenType"] != TOKEN_TYPE) {
            throw UnauthorizedException("Invalid link token")
        }

        val subject = claims.subject ?: throw UnauthorizedException("Invalid link token")
        val provider = claims["provider"] as? String ?: throw UnauthorizedException("Invalid link token")
        val email = claims["email"] as? String ?: throw UnauthorizedException("Invalid link token")

        return PendingSocialLink(
            provider = SocialAuthProvider.from(provider),
            providerSubject = subject,
            email = email.trim().lowercase(),
            displayName = claims["displayName"] as? String,
            avatarUrl = claims["avatarUrl"] as? String
        )
    }

    companion object {
        private const val TOKEN_TYPE = "SOCIAL_LINK"
    }
}

data class PendingSocialLink(
    val provider: SocialAuthProvider,
    val providerSubject: String,
    val email: String,
    val displayName: String?,
    val avatarUrl: String?
)
