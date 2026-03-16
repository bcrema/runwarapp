package com.runwar.notification

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.runwar.config.GlobalExceptionHandler
import com.runwar.config.UserPrincipal
import com.runwar.domain.user.User
import com.runwar.domain.user.UserRole
import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.http.MediaType
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.request.RequestPostProcessor
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean
import java.time.Instant
import java.util.UUID

class NotificationControllerTest {

    private val objectMapper = jacksonObjectMapper().findAndRegisterModules()
    private val notificationContractsService = mockk<NotificationContractsService>()
    private lateinit var mockMvc: MockMvc

    @BeforeEach
    fun setUp() {
        val validator = LocalValidatorFactoryBean().apply { afterPropertiesSet() }
        mockMvc = MockMvcBuilders.standaloneSetup(NotificationController(notificationContractsService))
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
    fun `notifications endpoint returns paginated inbox`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { notificationContractsService.getNotifications(userId, null, 20) } returns
            NotificationContractsService.NotificationInboxResponse(
                items = listOf(
                    NotificationContractsService.NotificationItem(
                        id = UUID.fromString("22222222-2222-2222-2222-222222222222"),
                        type = "mission_progress",
                        title = "Missao atualizada",
                        body = "Voce correu hoje",
                        data = mapOf("missionType" to "distance"),
                        read = false,
                        createdAt = Instant.parse("2026-03-16T12:00:00Z")
                    )
                ),
                nextCursor = "opaque-cursor",
                limit = 20
            )

        mockMvc.perform(
            get("/api/notifications")
                .with(authFor(userId))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.items[0].type").value("mission_progress"))
            .andExpect(jsonPath("$.nextCursor").value("opaque-cursor"))
    }

    @Test
    fun `push token endpoint stores device payload`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every {
            notificationContractsService.registerPushToken(
                userId = userId,
                platform = "ios",
                token = "token-123",
                appVersion = "1.0.0",
                deviceId = "device-1"
            )
        } returns NotificationContractsService.RegisterPushTokenResult(
            platform = "IOS",
            token = "token-123",
            appVersion = "1.0.0",
            deviceId = "device-1",
            updatedAt = Instant.parse("2026-03-16T12:00:00Z")
        )

        val payload = objectMapper.writeValueAsString(
            mapOf(
                "platform" to "ios",
                "token" to "token-123",
                "appVersion" to "1.0.0",
                "deviceId" to "device-1"
            )
        )

        mockMvc.perform(
            post("/api/devices/push-token")
                .with(authFor(userId))
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload)
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.platform").value("IOS"))
            .andExpect(jsonPath("$.deviceId").value("device-1"))
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
