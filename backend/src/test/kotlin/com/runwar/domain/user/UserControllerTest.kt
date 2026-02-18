package com.runwar.domain.user

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.runwar.config.GlobalExceptionHandler
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.http.MediaType
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean
import java.util.UUID

class UserControllerTest {

    private val objectMapper = jacksonObjectMapper()
    private val userService = mockk<UserService>()
    private val authRateLimiter = mockk<AuthRateLimiter>(relaxed = true)
    private lateinit var mockMvc: MockMvc

    @BeforeEach
    fun setUp() {
        val validator = LocalValidatorFactoryBean().apply { afterPropertiesSet() }
        mockMvc = MockMvcBuilders.standaloneSetup(UserController(userService, authRateLimiter))
            .setControllerAdvice(GlobalExceptionHandler())
            .setMessageConverters(MappingJackson2HttpMessageConverter(objectMapper))
            .setValidator(validator)
            .build()
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
                totalTilesConquered = 0
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
}
