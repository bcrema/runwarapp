package com.runwar.domain.user

import com.runwar.config.JwtProperties
import com.runwar.config.JwtService
import com.runwar.config.SocialLinkRequiredException
import com.runwar.config.UnauthorizedException
import java.security.MessageDigest
import java.security.SecureRandom
import java.text.Normalizer
import java.time.Instant
import java.util.Base64
import java.util.UUID
import org.slf4j.LoggerFactory
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class SocialAuthService(
    private val userRepository: UserRepository,
    private val userAuthIdentityRepository: UserAuthIdentityRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtService: JwtService,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val jwtProperties: JwtProperties,
    private val socialIdentityVerifier: SocialIdentityVerifier,
    private val socialLinkTokenService: SocialLinkTokenService
) {
    private val logger = LoggerFactory.getLogger(SocialAuthService::class.java)

    data class SocialExchangePayload(
        val provider: String,
        val idToken: String,
        val authorizationCode: String? = null,
        val nonce: String? = null,
        val emailHint: String? = null,
        val givenName: String? = null,
        val familyName: String? = null,
        val avatarUrl: String? = null
    )

    @Transactional
    fun exchange(payload: SocialExchangePayload): UserService.AuthResult {
        val provider = SocialAuthProvider.from(payload.provider)
        val verifiedIdentity = socialIdentityVerifier.verify(
            SocialVerificationRequest(
                provider = provider,
                idToken = payload.idToken,
                nonce = payload.nonce,
                emailHint = payload.emailHint,
                givenName = payload.givenName,
                familyName = payload.familyName,
                avatarUrl = payload.avatarUrl
            )
        )

        val existingIdentity = userAuthIdentityRepository.findWithUserByProviderAndProviderSubject(
            verifiedIdentity.provider,
            verifiedIdentity.subject
        )
        if (existingIdentity != null) {
            syncIdentity(existingIdentity, verifiedIdentity)
            logger.info(
                "social exchange success provider={} userId={} created=false",
                verifiedIdentity.provider.apiValue,
                existingIdentity.user.id
            )
            return createAuthResult(loadUser(existingIdentity.user.id))
        }

        val email = verifiedIdentity.email?.trim()?.lowercase()
            ?: throw UnauthorizedException("Verified email required")
        if (!verifiedIdentity.emailVerified) {
            throw UnauthorizedException("Verified email required")
        }

        val existingUser = userRepository.findWithBandeiraByEmailIgnoreCase(email)
        if (existingUser != null) {
            logger.info(
                "social exchange link required provider={} userId={} email={}",
                verifiedIdentity.provider.apiValue,
                existingUser.id,
                email
            )
            throw SocialLinkRequiredException(
                linkToken = socialLinkTokenService.generate(
                    PendingSocialLink(
                        provider = verifiedIdentity.provider,
                        providerSubject = verifiedIdentity.subject,
                        email = email,
                        displayName = verifiedIdentity.displayName,
                        avatarUrl = verifiedIdentity.avatarUrl
                    )
                ),
                provider = verifiedIdentity.provider.apiValue,
                emailMasked = maskEmail(email)
            )
        }

        val user = userRepository.save(
            User(
                email = email,
                username = generateUniqueUsername(verifiedIdentity.displayName ?: email.substringBefore("@")),
                passwordHash = passwordEncoder.encode("social-${UUID.randomUUID()}")
            ).apply {
                if (!verifiedIdentity.avatarUrl.isNullOrBlank()) {
                    avatarUrl = verifiedIdentity.avatarUrl
                }
            }
        )

        userAuthIdentityRepository.save(
            UserAuthIdentity(
                user = user,
                provider = verifiedIdentity.provider,
                providerSubject = verifiedIdentity.subject,
                providerEmail = email,
                emailVerified = verifiedIdentity.emailVerified,
                displayName = verifiedIdentity.displayName,
                avatarUrl = verifiedIdentity.avatarUrl
            )
        )

        logger.info(
            "social exchange success provider={} userId={} created=true",
            verifiedIdentity.provider.apiValue,
            user.id
        )
        return createAuthResult(loadUser(user.id))
    }

    @Transactional
    fun confirmLink(linkToken: String, email: String, password: String): UserService.AuthResult {
        val pendingLink = socialLinkTokenService.parse(linkToken)
        val normalizedEmail = email.trim().lowercase()

        if (normalizedEmail != pendingLink.email) {
            throw UnauthorizedException("Invalid link credentials")
        }

        val user = userRepository.findWithBandeiraByEmailIgnoreCase(normalizedEmail)
            ?: throw UnauthorizedException("Invalid link credentials")

        if (!passwordEncoder.matches(password, user.passwordHash)) {
            throw UnauthorizedException("Invalid link credentials")
        }

        val existingIdentity = userAuthIdentityRepository.findWithUserByProviderAndProviderSubject(
            pendingLink.provider,
            pendingLink.providerSubject
        )
        if (existingIdentity != null && existingIdentity.user.id != user.id) {
            throw IllegalStateException("Social identity is already linked to another account")
        }

        val identity = existingIdentity ?: UserAuthIdentity(
            user = user,
            provider = pendingLink.provider,
            providerSubject = pendingLink.providerSubject
        )

        identity.providerEmail = normalizedEmail
        identity.emailVerified = true
        identity.displayName = pendingLink.displayName ?: identity.displayName
        identity.avatarUrl = pendingLink.avatarUrl ?: identity.avatarUrl
        identity.lastLoginAt = Instant.now()
        userAuthIdentityRepository.save(identity)

        if (user.avatarUrl.isNullOrBlank() && !pendingLink.avatarUrl.isNullOrBlank()) {
            user.avatarUrl = pendingLink.avatarUrl
            userRepository.save(user)
        }

        logger.info(
            "social link success provider={} userId={}",
            pendingLink.provider.apiValue,
            user.id
        )
        return createAuthResult(loadUser(user.id))
    }

    private fun syncIdentity(identity: UserAuthIdentity, verifiedIdentity: VerifiedSocialIdentity) {
        identity.providerEmail = verifiedIdentity.email ?: identity.providerEmail
        identity.emailVerified = verifiedIdentity.emailVerified
        identity.displayName = verifiedIdentity.displayName ?: identity.displayName
        identity.avatarUrl = verifiedIdentity.avatarUrl ?: identity.avatarUrl
        identity.lastLoginAt = Instant.now()
        userAuthIdentityRepository.save(identity)

        if (identity.user.avatarUrl.isNullOrBlank() && !verifiedIdentity.avatarUrl.isNullOrBlank()) {
            identity.user.avatarUrl = verifiedIdentity.avatarUrl
            userRepository.save(identity.user)
        }
    }

    private fun loadUser(userId: UUID): User {
        return userRepository.findByIdWithBandeira(userId)
            ?: throw IllegalArgumentException("User not found")
    }

    private fun createAuthResult(user: User): UserService.AuthResult {
        val tokens = issueTokens(user)
        return UserService.AuthResult(
            user = UserService.UserDto.from(user),
            accessToken = tokens.accessToken,
            refreshToken = tokens.refreshToken
        )
    }

    private fun generateUniqueUsername(seed: String): String {
        val base = slugifyUsername(seed)
        if (!userRepository.existsByUsername(base)) {
            return base
        }

        var suffix = 2
        while (true) {
            val candidate = buildString {
                append(base.take(MAX_USERNAME_LENGTH - suffix.toString().length - 1))
                append("_")
                append(suffix)
            }
            if (!userRepository.existsByUsername(candidate)) {
                return candidate
            }
            suffix++
        }
    }

    private fun slugifyUsername(seed: String): String {
        val normalized = Normalizer.normalize(seed.trim().lowercase(), Normalizer.Form.NFD)
            .replace("\\p{M}+".toRegex(), "")
        val slug = normalized
            .replace("[^a-z0-9]+".toRegex(), "_")
            .trim('_')
            .ifBlank { DEFAULT_USERNAME }
        val candidate = slug.take(MAX_USERNAME_LENGTH)
        return when {
            candidate.length >= MIN_USERNAME_LENGTH -> candidate
            else -> (candidate + DEFAULT_USERNAME).take(MIN_USERNAME_LENGTH)
        }
    }

    private fun maskEmail(email: String): String {
        val parts = email.split("@", limit = 2)
        if (parts.size != 2) {
            return "***"
        }

        val localPart = parts[0]
        val domain = parts[1]
        val visiblePrefix = localPart.take(1)
        val visibleSuffix = localPart.takeLast(1).takeIf { localPart.length > 1 }.orEmpty()
        return "${visiblePrefix}***${visibleSuffix}@${domain}"
    }

    private data class TokenPair(
        val accessToken: String,
        val refreshToken: String
    )

    private fun issueTokens(user: User): TokenPair {
        val accessToken = jwtService.generateToken(user.id, user.email)
        val refreshToken = generateRefreshToken()
        val refreshTokenHash = hashToken(refreshToken)
        refreshTokenRepository.save(
            RefreshToken(
                user = user,
                tokenHash = refreshTokenHash,
                expiresAt = Instant.now().plusMillis(jwtProperties.refreshExpiration)
            )
        )
        return TokenPair(accessToken, refreshToken)
    }

    private fun generateRefreshToken(): String {
        val randomBytes = ByteArray(64)
        secureRandom.nextBytes(randomBytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes)
    }

    private fun hashToken(token: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashed = digest.digest(token.toByteArray(Charsets.UTF_8))
        return hashed.joinToString("") { "%02x".format(it) }
    }

    companion object {
        private const val DEFAULT_USERNAME = "runner"
        private const val MIN_USERNAME_LENGTH = 3
        private const val MAX_USERNAME_LENGTH = 30
        private val secureRandom = SecureRandom()
    }
}
