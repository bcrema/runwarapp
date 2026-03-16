package com.runwar.domain.user

import com.runwar.config.SocialAuthProperties
import com.runwar.config.UnauthorizedException
import java.security.MessageDigest
import java.util.Base64
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.security.oauth2.jwt.JwtException
import org.springframework.stereotype.Component

@Component
class JwtSocialIdentityVerifier(
    private val socialAuthProperties: SocialAuthProperties,
    private val decoderFactory: SocialJwtDecoderFactory
) : SocialIdentityVerifier {

    override fun verify(request: SocialVerificationRequest): VerifiedSocialIdentity {
        val jwt = try {
            decoderFactory.get(request.provider).decode(request.idToken)
        } catch (e: JwtException) {
            throw UnauthorizedException("Invalid social token")
        }

        val providerConfig = socialAuthProperties.provider(request.provider)
        validateIssuer(jwt, providerConfig.issuers)
        validateAudience(jwt, providerConfig.clientIds)
        validateNonce(jwt, request.nonce)

        val subject = jwt.subject ?: throw UnauthorizedException("Invalid social token")
        val email = jwt.getClaimAsString("email")?.trim()?.lowercase()
        val displayName = buildDisplayName(
            explicitName = listOfNotNull(request.givenName, request.familyName)
                .joinToString(" ")
                .trim()
                .ifBlank { null },
            tokenName = jwt.getClaimAsString("name"),
            email = email
        )

        return VerifiedSocialIdentity(
            provider = request.provider,
            subject = subject,
            email = email,
            emailVerified = parseBooleanClaim(jwt.claims["email_verified"]),
            displayName = displayName,
            avatarUrl = request.avatarUrl ?: jwt.getClaimAsString("picture")
        )
    }

    private fun validateIssuer(jwt: Jwt, allowedIssuers: List<String>) {
        val issuer = jwt.issuer?.toString()
        if (issuer.isNullOrBlank() || issuer !in allowedIssuers) {
            throw UnauthorizedException("Invalid social token")
        }
    }

    private fun validateAudience(jwt: Jwt, allowedClientIds: List<String>) {
        if (allowedClientIds.isEmpty()) {
            throw IllegalStateException("Social auth provider is not configured")
        }

        val audience = jwt.audience ?: emptyList()
        if (audience.none { it in allowedClientIds }) {
            throw UnauthorizedException("Invalid social token")
        }
    }

    private fun validateNonce(jwt: Jwt, providedNonce: String?) {
        if (providedNonce.isNullOrBlank()) {
            return
        }

        val tokenNonce = jwt.getClaimAsString("nonce")
        val hashedProvidedNonce = sha256(providedNonce)
        val base64ProvidedNonce = sha256Base64Url(providedNonce)

        if (tokenNonce.isNullOrBlank() || (tokenNonce != providedNonce && tokenNonce != hashedProvidedNonce && tokenNonce != base64ProvidedNonce)) {
            throw UnauthorizedException("Invalid social token")
        }
    }

    private fun buildDisplayName(explicitName: String?, tokenName: String?, email: String?): String? {
        return explicitName
            ?: tokenName?.trim()?.ifBlank { null }
            ?: email?.substringBefore("@")?.ifBlank { null }
    }

    private fun parseBooleanClaim(value: Any?): Boolean {
        return when (value) {
            is Boolean -> value
            is String -> value.equals("true", ignoreCase = true)
            else -> false
        }
    }

    private fun sha256(value: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        return digest.digest(value.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
    }

    private fun sha256Base64Url(value: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        return Base64.getUrlEncoder().withoutPadding()
            .encodeToString(digest.digest(value.toByteArray(Charsets.UTF_8)))
    }
}
