package com.runwar.domain.user

import com.runwar.config.SocialAuthProperties
import com.runwar.config.UnauthorizedException
import java.time.Instant
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Test
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.security.oauth2.jwt.JwtDecoder

class JwtSocialIdentityVerifierTest {

    private val properties = SocialAuthProperties(
        google = SocialAuthProperties.ProviderProperties(
            clientIds = listOf("google-web-client"),
            jwkSetUri = "https://example.com/google-jwks",
            issuers = listOf("https://accounts.google.com", "accounts.google.com")
        ),
        apple = SocialAuthProperties.ProviderProperties(
            clientIds = listOf("com.runwar.ligarun"),
            jwkSetUri = "https://example.com/apple-jwks",
            issuers = listOf("https://appleid.apple.com")
        )
    )

    @Test
    fun `verify extracts expected identity for valid token`() {
        val verifier = JwtSocialIdentityVerifier(
            properties,
            StaticSocialJwtDecoderFactory(
                jwtFor(
                    subject = "google-subject",
                    issuer = "https://accounts.google.com",
                    audience = listOf("google-web-client"),
                    claims = mapOf(
                        "email" to "user@example.com",
                        "email_verified" to true,
                        "name" to "Runner Name",
                        "picture" to "https://example.com/avatar.png"
                    )
                )
            )
        )

        val result = verifier.verify(
            SocialVerificationRequest(
                provider = SocialAuthProvider.GOOGLE,
                idToken = "token-123"
            )
        )

        assertEquals("google-subject", result.subject)
        assertEquals("user@example.com", result.email)
        assertEquals("Runner Name", result.displayName)
        assertEquals("https://example.com/avatar.png", result.avatarUrl)
    }

    @Test
    fun `verify rejects invalid issuer`() {
        val verifier = JwtSocialIdentityVerifier(
            properties,
            StaticSocialJwtDecoderFactory(
                jwtFor(
                    subject = "google-subject",
                    issuer = "https://evil.example.com",
                    audience = listOf("google-web-client"),
                    claims = mapOf(
                        "email" to "user@example.com",
                        "email_verified" to true
                    )
                )
            )
        )

        assertThrows(UnauthorizedException::class.java) {
            verifier.verify(
                SocialVerificationRequest(
                    provider = SocialAuthProvider.GOOGLE,
                    idToken = "token-123"
                )
            )
        }
    }

    @Test
    fun `verify rejects invalid audience`() {
        val verifier = JwtSocialIdentityVerifier(
            properties,
            StaticSocialJwtDecoderFactory(
                jwtFor(
                    subject = "google-subject",
                    issuer = "https://accounts.google.com",
                    audience = listOf("wrong-client"),
                    claims = mapOf(
                        "email" to "user@example.com",
                        "email_verified" to true
                    )
                )
            )
        )

        assertThrows(UnauthorizedException::class.java) {
            verifier.verify(
                SocialVerificationRequest(
                    provider = SocialAuthProvider.GOOGLE,
                    idToken = "token-123"
                )
            )
        }
    }

    private fun jwtFor(
        subject: String,
        issuer: String,
        audience: List<String>,
        claims: Map<String, Any>
    ): Jwt {
        val now = Instant.now()
        return Jwt(
            "token-123",
            now.minusSeconds(60),
            now.plusSeconds(300),
            mapOf("alg" to "RS256"),
            claims + mapOf(
                "sub" to subject,
                "iss" to issuer,
                "aud" to audience
            )
        )
    }

    private class StaticSocialJwtDecoderFactory(
        private val jwt: Jwt
    ) : SocialJwtDecoderFactory {
        override fun get(provider: SocialAuthProvider): JwtDecoder {
            return JwtDecoder { jwt }
        }
    }
}
