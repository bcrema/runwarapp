package com.runwar.domain.user

import com.runwar.config.JwtProperties
import com.runwar.config.JwtService
import com.runwar.config.UnauthorizedException
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.security.crypto.password.PasswordEncoder
import java.time.Instant
import java.util.UUID

class UserServiceTest {

    @Test
    fun `register throws when email already exists`() {
        val userRepository = mockk<UserRepository>()
        val passwordEncoder = mockk<PasswordEncoder>()
        val jwtService = mockk<JwtService>()
        val refreshTokenRepository = mockk<RefreshTokenRepository>()
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)

        every { userRepository.existsByEmail("user@example.com") } returns true

        val service = UserService(
            userRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties
        )

        assertThrows(IllegalArgumentException::class.java) {
            service.register("user@example.com", "user", "password")
        }

        verify(exactly = 0) { userRepository.save(any()) }
    }

    @Test
    fun `register creates user and issues refresh token`() {
        val userRepository = mockk<UserRepository>()
        val passwordEncoder = mockk<PasswordEncoder>()
        val jwtService = mockk<JwtService>()
        val refreshTokenRepository = mockk<RefreshTokenRepository>()
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)

        every { userRepository.existsByEmail(any()) } returns false
        every { userRepository.existsByUsername(any()) } returns false
        every { passwordEncoder.encode("password") } returns "encoded"
        every { jwtService.generateToken(any(), any()) } returns "access-token"

        val savedUserSlot = slot<User>()
        every { userRepository.save(capture(savedUserSlot)) } answers { savedUserSlot.captured }

        val savedRefreshTokens = mutableListOf<RefreshToken>()
        every { refreshTokenRepository.save(capture(savedRefreshTokens)) } answers { firstArg() }

        val service = UserService(
            userRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties
        )

        val result = service.register("user@example.com", "user", "password")

        assertEquals("user@example.com", result.user.email)
        assertEquals("user", result.user.username)
        assertEquals("access-token", result.accessToken)
        assertTrue(result.refreshToken.length in 80..100)
        assertTrue(result.refreshToken.matches(Regex("^[A-Za-z0-9_-]+$")))

        assertEquals("encoded", savedUserSlot.captured.passwordHash)

        assertEquals(1, savedRefreshTokens.size)
        assertEquals(savedUserSlot.captured, savedRefreshTokens.single().user)
        assertTrue(savedRefreshTokens.single().tokenHash.matches(Regex("^[a-f0-9]{64}$")))
    }

    @Test
    fun `refresh rejects invalid refresh token format before hitting repository`() {
        val userRepository = mockk<UserRepository>(relaxed = true)
        val passwordEncoder = mockk<PasswordEncoder>(relaxed = true)
        val jwtService = mockk<JwtService>(relaxed = true)
        val refreshTokenRepository = mockk<RefreshTokenRepository>(relaxed = true)
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)

        val service = UserService(
            userRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties
        )

        assertThrows(UnauthorizedException::class.java) {
            service.refresh("short")
        }

        verify(exactly = 0) { refreshTokenRepository.findByTokenHash(any()) }
    }

    @Test
    fun `refresh rotates token and revokes previous`() {
        val userRepository = mockk<UserRepository>(relaxed = true)
        val passwordEncoder = mockk<PasswordEncoder>(relaxed = true)
        val jwtService = mockk<JwtService>()
        val refreshTokenRepository = mockk<RefreshTokenRepository>()
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)

        val user = User(
            id = UUID.randomUUID(),
            email = "user@example.com",
            username = "user",
            passwordHash = "hash"
        )
        val stored = RefreshToken(
            user = user,
            tokenHash = "old-hash",
            expiresAt = Instant.now().plusSeconds(3600)
        )

        every { jwtService.generateToken(user.id, user.email) } returns "new-access-token"
        every { refreshTokenRepository.findByTokenHash(any()) } returns stored

        val saved = mutableListOf<RefreshToken>()
        every { refreshTokenRepository.save(capture(saved)) } answers { firstArg() }

        val service = UserService(
            userRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties
        )

        val inputRefreshToken = "A".repeat(86)
        val result = service.refresh(inputRefreshToken)

        assertEquals("new-access-token", result.accessToken)
        assertTrue(result.refreshToken.length in 80..100)
        assertTrue(result.refreshToken.matches(Regex("^[A-Za-z0-9_-]+$")))
        assertNotNull(result.user)

        assertEquals(2, saved.size)
        val revokedOld = saved[0]
        val newTokenRecord = saved[1]

        assertNotNull(revokedOld.revokedAt)
        assertNotNull(revokedOld.replacedByTokenHash)
        assertEquals(revokedOld.replacedByTokenHash, newTokenRecord.tokenHash)
        assertEquals(user, newTokenRecord.user)
        assertEquals(null, newTokenRecord.revokedAt)
    }

    @Test
    fun `logout revokes token when present`() {
        val userRepository = mockk<UserRepository>(relaxed = true)
        val passwordEncoder = mockk<PasswordEncoder>(relaxed = true)
        val jwtService = mockk<JwtService>(relaxed = true)
        val refreshTokenRepository = mockk<RefreshTokenRepository>()
        val jwtProperties = JwtProperties(refreshExpiration = 3_600_000)

        val user = User(
            id = UUID.randomUUID(),
            email = "user@example.com",
            username = "user",
            passwordHash = "hash"
        )
        val stored = RefreshToken(
            user = user,
            tokenHash = "hash",
            expiresAt = Instant.now().plusSeconds(3600),
            revokedAt = null
        )

        every { refreshTokenRepository.findByTokenHash(any()) } returns stored
        every { refreshTokenRepository.save(any()) } answers { firstArg() }

        val service = UserService(
            userRepository,
            passwordEncoder,
            jwtService,
            refreshTokenRepository,
            jwtProperties
        )

        service.logout("A".repeat(86))

        verify(exactly = 1) { refreshTokenRepository.save(match { it.revokedAt != null }) }
    }
}
