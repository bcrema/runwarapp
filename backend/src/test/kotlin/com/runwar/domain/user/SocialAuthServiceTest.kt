package com.runwar.domain.user

import com.runwar.config.JwtProperties
import com.runwar.config.JwtService
import com.runwar.config.SocialLinkRequiredException
import com.runwar.config.UnauthorizedException
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import java.time.Instant
import java.util.UUID
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.security.crypto.password.PasswordEncoder

class SocialAuthServiceTest {

    @Test
    fun `exchange creates new social user and identity`() {
        val userRepository = mockk<UserRepository>()
        val identityRepository = mockk<UserAuthIdentityRepository>()
        val passwordEncoder = mockk<PasswordEncoder>()
        val jwtService = mockk<JwtService>()
        val refreshTokenRepository = mockk<RefreshTokenRepository>()
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)
        val verifier = mockk<SocialIdentityVerifier>()
        val linkTokenService = mockk<SocialLinkTokenService>()

        every {
            verifier.verify(
                SocialVerificationRequest(
                    provider = SocialAuthProvider.GOOGLE,
                    idToken = "id-token",
                    nonce = null,
                    emailHint = null,
                    givenName = null,
                    familyName = null,
                    avatarUrl = null
                )
            )
        } returns VerifiedSocialIdentity(
            provider = SocialAuthProvider.GOOGLE,
            subject = "google-subject",
            email = "user@example.com",
            emailVerified = true,
            displayName = "Runner Name",
            avatarUrl = "https://example.com/avatar.png"
        )
        every { identityRepository.findWithUserByProviderAndProviderSubject(SocialAuthProvider.GOOGLE, "google-subject") } returns null
        every { userRepository.findWithBandeiraByEmailIgnoreCase("user@example.com") } returns null
        every { userRepository.existsByUsername("runner_name") } returns false
        every { passwordEncoder.encode(match { it.startsWith("social-") }) } returns "encoded-social"
        every { jwtService.generateToken(any(), "user@example.com") } returns "access-token"

        val savedUser = slot<User>()
        every { userRepository.save(capture(savedUser)) } answers { savedUser.captured }
        every { userRepository.findByIdWithBandeira(any()) } answers { savedUser.captured }

        val savedIdentity = slot<UserAuthIdentity>()
        every { identityRepository.save(capture(savedIdentity)) } answers { savedIdentity.captured }

        val savedRefreshTokens = mutableListOf<RefreshToken>()
        every { refreshTokenRepository.save(capture(savedRefreshTokens)) } answers { firstArg() }

        val service = SocialAuthService(
            userRepository,
            identityRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties,
            verifier,
            linkTokenService
        )

        val result = service.exchange(
            SocialAuthService.SocialExchangePayload(
                provider = "google",
                idToken = "id-token"
            )
        )

        assertEquals("user@example.com", result.user.email)
        assertEquals("runner_name", result.user.username)
        assertEquals("https://example.com/avatar.png", result.user.avatarUrl)
        assertEquals("access-token", result.accessToken)
        assertTrue(result.refreshToken.length in 80..100)
        assertEquals("google-subject", savedIdentity.captured.providerSubject)
        assertEquals(SocialAuthProvider.GOOGLE, savedIdentity.captured.provider)
        assertEquals(savedUser.captured, savedIdentity.captured.user)
        assertEquals(1, savedRefreshTokens.size)
    }

    @Test
    fun `exchange returns auth for linked identity without requiring email`() {
        val userRepository = mockk<UserRepository>()
        val identityRepository = mockk<UserAuthIdentityRepository>()
        val passwordEncoder = mockk<PasswordEncoder>(relaxed = true)
        val jwtService = mockk<JwtService>()
        val refreshTokenRepository = mockk<RefreshTokenRepository>()
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)
        val verifier = mockk<SocialIdentityVerifier>()
        val linkTokenService = mockk<SocialLinkTokenService>(relaxed = true)

        val user = User(
            id = UUID.randomUUID(),
            email = "user@example.com",
            username = "runner",
            passwordHash = "hash"
        )
        val identity = UserAuthIdentity(
            user = user,
            provider = SocialAuthProvider.APPLE,
            providerSubject = "apple-subject",
            providerEmail = "user@example.com",
            emailVerified = true
        )

        every { verifier.verify(any()) } returns VerifiedSocialIdentity(
            provider = SocialAuthProvider.APPLE,
            subject = "apple-subject",
            email = null,
            emailVerified = false,
            displayName = null,
            avatarUrl = null
        )
        every { identityRepository.findWithUserByProviderAndProviderSubject(SocialAuthProvider.APPLE, "apple-subject") } returns identity
        every { identityRepository.save(any()) } answers { firstArg() }
        every { userRepository.findByIdWithBandeira(user.id) } returns user
        every { jwtService.generateToken(user.id, user.email) } returns "access-token"
        every { refreshTokenRepository.save(any()) } answers { firstArg() }

        val service = SocialAuthService(
            userRepository,
            identityRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties,
            verifier,
            linkTokenService
        )

        val result = service.exchange(
            SocialAuthService.SocialExchangePayload(
                provider = "apple",
                idToken = "id-token"
            )
        )

        assertEquals(user.email, result.user.email)
        assertEquals("access-token", result.accessToken)
        assertNotNull(result.refreshToken)
        verify(exactly = 0) { userRepository.save(any()) }
    }

    @Test
    fun `exchange throws link required when email already belongs to another user`() {
        val userRepository = mockk<UserRepository>()
        val identityRepository = mockk<UserAuthIdentityRepository>()
        val passwordEncoder = mockk<PasswordEncoder>(relaxed = true)
        val jwtService = mockk<JwtService>(relaxed = true)
        val refreshTokenRepository = mockk<RefreshTokenRepository>(relaxed = true)
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)
        val verifier = mockk<SocialIdentityVerifier>()
        val linkTokenService = mockk<SocialLinkTokenService>()

        val existingUser = User(
            id = UUID.randomUUID(),
            email = "user@example.com",
            username = "runner",
            passwordHash = "hash"
        )

        every { verifier.verify(any()) } returns VerifiedSocialIdentity(
            provider = SocialAuthProvider.GOOGLE,
            subject = "google-subject",
            email = "user@example.com",
            emailVerified = true,
            displayName = "Runner",
            avatarUrl = null
        )
        every { identityRepository.findWithUserByProviderAndProviderSubject(SocialAuthProvider.GOOGLE, "google-subject") } returns null
        every { userRepository.findWithBandeiraByEmailIgnoreCase("user@example.com") } returns existingUser
        every { linkTokenService.generate(any()) } returns "link-token-123"

        val service = SocialAuthService(
            userRepository,
            identityRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties,
            verifier,
            linkTokenService
        )

        val exception = assertThrows(SocialLinkRequiredException::class.java) {
            service.exchange(
                SocialAuthService.SocialExchangePayload(
                    provider = "google",
                    idToken = "id-token"
                )
            )
        }

        assertEquals("link-token-123", exception.linkToken)
        assertEquals("google", exception.provider)
        assertEquals("u***r@example.com", exception.emailMasked)
    }

    @Test
    fun `confirm link validates credentials and stores linked identity`() {
        val userRepository = mockk<UserRepository>()
        val identityRepository = mockk<UserAuthIdentityRepository>()
        val passwordEncoder = mockk<PasswordEncoder>()
        val jwtService = mockk<JwtService>()
        val refreshTokenRepository = mockk<RefreshTokenRepository>()
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)
        val verifier = mockk<SocialIdentityVerifier>(relaxed = true)
        val linkTokenService = mockk<SocialLinkTokenService>()

        val user = User(
            id = UUID.randomUUID(),
            email = "user@example.com",
            username = "runner",
            passwordHash = "stored-hash"
        )

        every {
            linkTokenService.parse("link-token-123")
        } returns PendingSocialLink(
            provider = SocialAuthProvider.GOOGLE,
            providerSubject = "google-subject",
            email = "user@example.com",
            displayName = "Runner",
            avatarUrl = "https://example.com/avatar.png"
        )
        every { userRepository.findWithBandeiraByEmailIgnoreCase("user@example.com") } returns user
        every { passwordEncoder.matches("secret", "stored-hash") } returns true
        every { identityRepository.findWithUserByProviderAndProviderSubject(SocialAuthProvider.GOOGLE, "google-subject") } returns null
        every { identityRepository.save(any()) } answers { firstArg() }
        every { userRepository.save(any()) } answers { firstArg() }
        every { userRepository.findByIdWithBandeira(user.id) } returns user
        every { jwtService.generateToken(user.id, user.email) } returns "access-token"
        every { refreshTokenRepository.save(any()) } answers { firstArg() }

        val service = SocialAuthService(
            userRepository,
            identityRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties,
            verifier,
            linkTokenService
        )

        val result = service.confirmLink("link-token-123", "user@example.com", "secret")

        assertEquals("access-token", result.accessToken)
        assertEquals("https://example.com/avatar.png", user.avatarUrl)
        verify(exactly = 1) { identityRepository.save(match { it.providerSubject == "google-subject" && it.provider == SocialAuthProvider.GOOGLE }) }
    }

    @Test
    fun `confirm link rejects invalid credentials`() {
        val userRepository = mockk<UserRepository>()
        val identityRepository = mockk<UserAuthIdentityRepository>(relaxed = true)
        val passwordEncoder = mockk<PasswordEncoder>()
        val jwtService = mockk<JwtService>(relaxed = true)
        val refreshTokenRepository = mockk<RefreshTokenRepository>(relaxed = true)
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)
        val verifier = mockk<SocialIdentityVerifier>(relaxed = true)
        val linkTokenService = mockk<SocialLinkTokenService>()

        val user = User(
            id = UUID.randomUUID(),
            email = "user@example.com",
            username = "runner",
            passwordHash = "stored-hash"
        )

        every { linkTokenService.parse("link-token-123") } returns PendingSocialLink(
            provider = SocialAuthProvider.GOOGLE,
            providerSubject = "google-subject",
            email = "user@example.com",
            displayName = null,
            avatarUrl = null
        )
        every { userRepository.findWithBandeiraByEmailIgnoreCase("user@example.com") } returns user
        every { passwordEncoder.matches("wrong", "stored-hash") } returns false

        val service = SocialAuthService(
            userRepository,
            identityRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties,
            verifier,
            linkTokenService
        )

        assertThrows(UnauthorizedException::class.java) {
            service.confirmLink("link-token-123", "user@example.com", "wrong")
        }
    }

    @Test
    fun `exchange resolves username collisions with numeric suffix`() {
        val userRepository = mockk<UserRepository>()
        val identityRepository = mockk<UserAuthIdentityRepository>()
        val passwordEncoder = mockk<PasswordEncoder>()
        val jwtService = mockk<JwtService>()
        val refreshTokenRepository = mockk<RefreshTokenRepository>()
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)
        val verifier = mockk<SocialIdentityVerifier>()
        val linkTokenService = mockk<SocialLinkTokenService>(relaxed = true)

        every { verifier.verify(any()) } returns VerifiedSocialIdentity(
            provider = SocialAuthProvider.GOOGLE,
            subject = "google-subject",
            email = "user@example.com",
            emailVerified = true,
            displayName = "Runner",
            avatarUrl = null
        )
        every { identityRepository.findWithUserByProviderAndProviderSubject(SocialAuthProvider.GOOGLE, "google-subject") } returns null
        every { userRepository.findWithBandeiraByEmailIgnoreCase("user@example.com") } returns null
        every { userRepository.existsByUsername("runner") } returns true
        every { userRepository.existsByUsername("runner_2") } returns false
        every { passwordEncoder.encode(any()) } returns "encoded-social"
        every { jwtService.generateToken(any(), any()) } returns "access-token"

        val savedUser = slot<User>()
        every { userRepository.save(capture(savedUser)) } answers { savedUser.captured }
        every { userRepository.findByIdWithBandeira(any()) } returns User(
            id = UUID.randomUUID(),
            email = "user@example.com",
            username = "runner_2",
            passwordHash = "encoded-social"
        )
        every { identityRepository.save(any()) } answers { firstArg() }
        every { refreshTokenRepository.save(any()) } answers { firstArg() }

        val service = SocialAuthService(
            userRepository,
            identityRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties,
            verifier,
            linkTokenService
        )

        service.exchange(
            SocialAuthService.SocialExchangePayload(
                provider = "google",
                idToken = "id-token"
            )
        )

        assertEquals("runner_2", savedUser.captured.username)
    }
}
