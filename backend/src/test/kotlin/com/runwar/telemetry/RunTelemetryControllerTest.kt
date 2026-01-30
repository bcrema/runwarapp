package com.runwar.telemetry

import com.runwar.config.GlobalExceptionHandler
import com.runwar.config.UserPrincipal
import com.runwar.domain.run.RunOrigin
import com.runwar.domain.run.RunStatus
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.user.User
import com.runwar.domain.user.UserRole
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.http.MediaType
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.RequestPostProcessor
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.content
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import java.time.Duration
import java.time.Instant
import java.util.UUID

class RunTelemetryControllerTest {
    private lateinit var mockMvc: MockMvc
    private val runTelemetryService = mockk<RunTelemetryService>(relaxed = true)

    @BeforeEach
    fun setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(RunTelemetryController(runTelemetryService))
            .setControllerAdvice(GlobalExceptionHandler())
            .setCustomArgumentResolvers(AuthenticationPrincipalArgumentResolver())
            .build()
    }

    @AfterEach
    fun tearDown() {
        SecurityContextHolder.clearContext()
    }

    @Test
    fun `non-admin users cannot export telemetry`() {
        mockMvc.perform(
            get("/api/admin/telemetry/runs")
                .with(authFor(UserRole.MEMBER))
        )
            .andExpect(status().isForbidden)
    }

    @Test
    fun `defaults date range and returns json`() {
        val startSlot = slot<Instant>()
        val endSlot = slot<Instant>()
        every { runTelemetryService.fetchEvents(capture(startSlot), capture(endSlot)) } returns emptyList()
        every { runTelemetryService.buildJson(emptyList()) } returns "[]"

        mockMvc.perform(
            get("/api/admin/telemetry/runs")
                .with(authFor(UserRole.ADMIN))
        )
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(content().string("[]"))

        assertTrue(!startSlot.captured.isAfter(endSlot.captured))
        val minutes = Duration.between(startSlot.captured, endSlot.captured).toMinutes()
        assertTrue(minutes in (23 * 60)..(25 * 60))
    }

    @Test
    fun `csv exports return csv content type`() {
        val event =
            RunTelemetryEvent(
                runId = UUID.randomUUID(),
                userId = UUID.randomUUID(),
                origin = RunOrigin.IMPORT,
                status = RunStatus.VALIDATED,
                isLoopValid = true,
                loopDistanceMeters = 10.0,
                loopDurationSeconds = 600,
                closureMeters = 2.0,
                coveragePct = 0.7,
                primaryTileId = "tile-1",
                tilesCoveredCount = 1,
                tilesCovered = listOf("tile-1"),
                actionType = TerritoryActionType.CONQUEST,
                actionSuccess = true,
                actionReason = null,
                shieldBefore = 0,
                shieldAfter = 100,
                cooldownUntil = null,
                userCapReached = false,
                bandeiraCapReached = false,
                actionsToday = 1,
                bandeiraActionsToday = null,
                userActionsRemaining = 4,
                bandeiraActionsRemaining = null,
                fraudFlags = emptyList(),
                rejectionReasons = emptyList(),
                payloadJson = "{}",
                createdAt = Instant.parse("2024-01-01T00:00:00Z")
            )
        every { runTelemetryService.fetchEvents(any(), any()) } returns listOf(event)
        every { runTelemetryService.buildCsv(listOf(event)) } returns "createdAt,runId\n"

        mockMvc.perform(
            get("/api/admin/telemetry/runs")
                .param("format", "csv")
                .with(authFor(UserRole.ADMIN))
        )
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType("text", "csv")))
            .andExpect(content().string("createdAt,runId\n"))
    }

    private fun authFor(role: UserRole) = RequestPostProcessor { request ->
        val principal =
            UserPrincipal(
                User(
                    id = UUID.randomUUID(),
                    email = "${role.name.lowercase()}@example.com",
                    username = role.name.lowercase(),
                    passwordHash = "hash",
                    role = role
                )
            )
        val auth = UsernamePasswordAuthenticationToken(principal, null, principal.authorities)
        SecurityContextHolder.getContext().authentication = auth
        request
    }
}
