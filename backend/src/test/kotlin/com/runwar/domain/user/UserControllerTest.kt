package com.runwar.domain.user

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.runwar.config.SocialLinkRequiredException
import com.runwar.config.GlobalExceptionHandler
import com.runwar.config.UserPrincipal
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.http.MediaType
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.request.RequestPostProcessor
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean
import java.time.Instant
import com.runwar.domain.user.UserRole
import java.util.UUID

class UserControllerTest {

    private val objectMapper = jacksonObjectMapper().findAndRegisterModules()
    private val userService = mockk<UserService>()
    private val socialAuthService = mockk<SocialAuthService>()
    private val authRateLimiter = mockk<AuthRateLimiter>(relaxed = true)
    private val userContractsService = mockk<UserContractsService>()
    private lateinit var mockMvc: MockMvc

    @BeforeEach
    fun setUp() {
        val validator = LocalValidatorFactoryBean().apply { afterPropertiesSet() }
        mockMvc = MockMvcBuilders.standaloneSetup(UserController(userService, socialAuthService, authRateLimiter, userContractsService))
            .setControllerAdvice(GlobalExceptionHandler())
            .setMessageConverters(MappingJackson2HttpMessageConverter(objectMapper))
            .setValidator(validator)
            .setCustomArgumentResolvers(AuthenticationPrincipalArgumentResolver())
            .build()
    }

    @AfterEach
    fun tearDown() {
        SecurityContextHolder.clearContext()
    }

    @Test
    fun `signup enforces rate limit and returns auth response`() {
        val result = UserService.AuthResult(
            user = UserService.UserDto(
                id = UUID.randomUUID(),
                email = "user@example.com",
                username = "user",
                avatarUrl = null,
                isPublic = true,
                bandeiraId = null,
                bandeiraName = null,
                role = "MEMBER",
                totalRuns = 0,
                totalDistance = 0.0,
                totalDistanceMeters = 0.0,
                totalQuadrasConquered = 0
            ),
            accessToken = "access-token",
            refreshToken = "refresh-token"
        )
        every { userService.register("user@example.com", "user", "password") } returns result

        val payload = objectMapper.writeValueAsString(
            mapOf(
                "email" to "user@example.com",
                "username" to "user",
                "password" to "password"
            )
        )

        mockMvc.perform(
            post("/api/auth/signup")
                .header("X-Forwarded-For", "1.2.3.4")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.accessToken").value("access-token"))
            .andExpect(jsonPath("$.refreshToken").value("refresh-token"))
            .andExpect(jsonPath("$.user.email").value("user@example.com"))

        verify(exactly = 1) { authRateLimiter.check("signup:ip:1.2.3.4") }
        verify(exactly = 1) { authRateLimiter.check("signup:email:user@example.com") }
    }

    @Test
    fun `signup validation errors return VALIDATION_ERROR`() {
        val payload = objectMapper.writeValueAsString(
            mapOf(
                "email" to "not-an-email",
                "username" to "u",
                "password" to "123"
            )
        )

        mockMvc.perform(
            post("/api/auth/signup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
        )
            .andExpect(status().isBadRequest)
            .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
            .andExpect(jsonPath("$.details.email").exists())
            .andExpect(jsonPath("$.details.username").exists())
            .andExpect(jsonPath("$.details.password").exists())
    }

    @Test
    fun `login records failures only on invalid credentials`() {
        every { userService.login("user@example.com", "wrong-password") } throws IllegalArgumentException("Invalid credentials")

        val payload = objectMapper.writeValueAsString(
            mapOf(
                "email" to "user@example.com",
                "password" to "wrong-password"
            )
        )

        mockMvc.perform(
            post("/api/auth/login")
                .header("X-Forwarded-For", "1.2.3.4")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
        )
            .andExpect(status().isUnauthorized)
            .andExpect(jsonPath("$.error").value("UNAUTHORIZED"))

        verify(exactly = 1) { authRateLimiter.ensureAllowed("login:ip:1.2.3.4") }
        verify(exactly = 1) { authRateLimiter.ensureAllowed("login:email:user@example.com") }
        verify(exactly = 1) { authRateLimiter.recordFailure("login:ip:1.2.3.4") }
        verify(exactly = 1) { authRateLimiter.recordFailure("login:email:user@example.com") }
        verify(exactly = 0) { authRateLimiter.reset(any()) }
    }

    @Test
    fun `login success resets rate limiter counters`() {
        val result = UserService.AuthResult(
            user = UserService.UserDto(
                id = UUID.randomUUID(),
                email = "user@example.com",
                username = "user",
                avatarUrl = null,
                isPublic = true,
                bandeiraId = null,
                bandeiraName = null,
                role = "MEMBER",
                totalRuns = 0,
                totalDistance = 0.0,
                totalDistanceMeters = 0.0,
                totalQuadrasConquered = 0
            ),
            accessToken = "access-token",
            refreshToken = "refresh-token"
        )
        every { userService.login("user@example.com", "password") } returns result

        val payload = objectMapper.writeValueAsString(
            mapOf(
                "email" to "user@example.com",
                "password" to "password"
            )
        )

        mockMvc.perform(
            post("/api/auth/login")
                .header("X-Forwarded-For", "1.2.3.4")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.accessToken").value("access-token"))

        verify(exactly = 1) { authRateLimiter.ensureAllowed("login:ip:1.2.3.4") }
        verify(exactly = 1) { authRateLimiter.ensureAllowed("login:email:user@example.com") }
        verify(exactly = 1) { authRateLimiter.reset("login:ip:1.2.3.4") }
        verify(exactly = 1) { authRateLimiter.reset("login:email:user@example.com") }
        verify(exactly = 0) { authRateLimiter.recordFailure("login:ip:1.2.3.4") }
        verify(exactly = 0) { authRateLimiter.recordFailure("login:email:user@example.com") }
    }

    @Test
    fun `social exchange success resets rate limiter and returns auth response`() {
        val result = UserService.AuthResult(
            user = UserService.UserDto(
                id = UUID.randomUUID(),
                email = "user@example.com",
                username = "runner",
                avatarUrl = null,
                isPublic = true,
                bandeiraId = null,
                bandeiraName = null,
                role = "MEMBER",
                totalRuns = 0,
                totalDistance = 0.0,
                totalDistanceMeters = 0.0,
                totalQuadrasConquered = 0
            ),
            accessToken = "access-token",
            refreshToken = "refresh-token"
        )
        every {
            socialAuthService.exchange(
                SocialAuthService.SocialExchangePayload(
                    provider = "google",
                    idToken = "token-123",
                    authorizationCode = null,
                    nonce = null,
                    emailHint = null,
                    givenName = null,
                    familyName = null,
                    avatarUrl = null
                )
            )
        } returns result

        val payload = objectMapper.writeValueAsString(
            mapOf(
                "provider" to "google",
                "idToken" to "token-123"
            )
        )

        mockMvc.perform(
            post("/api/auth/social/exchange")
                .header("X-Forwarded-For", "1.2.3.4")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.accessToken").value("access-token"))
            .andExpect(jsonPath("$.user.username").value("runner"))

        verify(exactly = 1) { authRateLimiter.ensureAllowed("social-exchange:ip:1.2.3.4") }
        verify(exactly = 1) { authRateLimiter.reset("social-exchange:ip:1.2.3.4") }
    }

    @Test
    fun `social exchange returns link required conflict payload`() {
        every {
            socialAuthService.exchange(any())
        } throws SocialLinkRequiredException(
            linkToken = "link-token-123",
            provider = "google",
            emailMasked = "u***r@example.com"
        )

        val payload = objectMapper.writeValueAsString(
            mapOf(
                "provider" to "google",
                "idToken" to "token-123"
            )
        )

        mockMvc.perform(
            post("/api/auth/social/exchange")
                .header("X-Forwarded-For", "1.2.3.4")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
        )
            .andExpect(status().isConflict)
            .andExpect(jsonPath("$.error").value("LINK_REQUIRED"))
            .andExpect(jsonPath("$.linkToken").value("link-token-123"))
            .andExpect(jsonPath("$.provider").value("google"))
            .andExpect(jsonPath("$.emailMasked").value("u***r@example.com"))
    }

    @Test
    fun `social link confirm invalid credentials records failure`() {
        every {
            socialAuthService.confirmLink("link-token-123", "user@example.com", "wrong")
        } throws com.runwar.config.UnauthorizedException("Invalid link credentials")

        val payload = objectMapper.writeValueAsString(
            mapOf(
                "linkToken" to "link-token-123",
                "email" to "user@example.com",
                "password" to "wrong"
            )
        )

        mockMvc.perform(
            post("/api/auth/social/link/confirm")
                .header("X-Forwarded-For", "1.2.3.4")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
        )
            .andExpect(status().isUnauthorized)
            .andExpect(jsonPath("$.error").value("UNAUTHORIZED"))

        verify(exactly = 1) { authRateLimiter.ensureAllowed("social-link:ip:1.2.3.4") }
        verify(exactly = 1) { authRateLimiter.ensureAllowed("social-link:email:user@example.com") }
        verify(exactly = 1) { authRateLimiter.recordFailure("social-link:ip:1.2.3.4") }
        verify(exactly = 1) { authRateLimiter.recordFailure("social-link:email:user@example.com") }
    }

    @Test
    fun `authenticated rankings endpoint returns current user entry`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { userContractsService.getUserRankings(userId, "season") } returns
            UserContractsService.UserRankingResponse(
                seasonId = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
                seasonName = "Temporada 1",
                scope = "season",
                generatedAt = Instant.parse("2026-03-16T12:00:00Z"),
                entries = listOf(
                    UserContractsService.UserRankingEntry(
                        position = 1,
                        userId = userId,
                        username = "runner",
                        avatarUrl = null,
                        bandeiraId = null,
                        bandeiraName = null,
                        dailyPoints = 12,
                        clusterBonus = 3,
                        totalPoints = 15
                    )
                ),
                currentUserEntry = UserContractsService.UserRankingEntry(
                    position = 1,
                    userId = userId,
                    username = "runner",
                    avatarUrl = null,
                    bandeiraId = null,
                    bandeiraName = null,
                    dailyPoints = 12,
                    clusterBonus = 3,
                    totalPoints = 15
                )
            )

        mockMvc.perform(
            get("/api/users/rankings")
                .with(authFor(userId))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.seasonName").value("Temporada 1"))
            .andExpect(jsonPath("$.entries[0].totalPoints").value(15))
            .andExpect(jsonPath("$.currentUserEntry.userId").value(userId.toString()))
    }

    @Test
    fun `authenticated badges endpoint returns progress payload`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { userContractsService.getMyBadges(userId) } returns listOf(
            UserContractsService.BadgeResponse(
                badgeId = UUID.fromString("22222222-2222-2222-2222-222222222222"),
                slug = "marathon",
                name = "Maratonista",
                description = "Complete 10km",
                iconUrl = null,
                earnedAt = null,
                progress = UserContractsService.BadgeProgress(
                    criteriaType = "distance",
                    currentValue = 5600,
                    targetValue = 10000,
                    unit = "meters",
                    completed = false
                )
            )
        )

        mockMvc.perform(
            get("/api/users/me/badges")
                .with(authFor(userId))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$[0].slug").value("marathon"))
            .andExpect(jsonPath("$[0].progress.criteriaType").value("distance"))
            .andExpect(jsonPath("$[0].progress.currentValue").value(5600))
    }

    @Test
    fun `authenticated active missions endpoint returns weekly missions`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { userContractsService.getActiveMissions(userId) } returns listOf(
            UserContractsService.ActiveMissionResponse(
                missionId = UUID.fromString("33333333-3333-3333-3333-333333333333"),
                weekStart = java.time.LocalDate.parse("2026-03-16"),
                missionType = "distance",
                targetValue = 15000,
                currentValue = 8400,
                completed = false
            )
        )

        mockMvc.perform(
            get("/api/users/me/missions/active")
                .with(authFor(userId))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$[0].missionType").value("distance"))
            .andExpect(jsonPath("$[0].targetValue").value(15000))
    }

    private fun authFor(userId: UUID) = RequestPostProcessor { request ->
        val principal = UserPrincipal(
            User(
                id = userId,
                email = "user@example.com",
                username = "user",
                passwordHash = "hash",
                role = UserRole.MEMBER
            )
        )
        val authentication = UsernamePasswordAuthenticationToken(principal, null, principal.authorities)
        SecurityContextHolder.getContext().authentication = authentication
        request.userPrincipal = authentication
        request
    }
}
