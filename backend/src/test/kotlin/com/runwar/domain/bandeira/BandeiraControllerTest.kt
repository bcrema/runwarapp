package com.runwar.domain.bandeira

import com.runwar.config.GlobalExceptionHandler
import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import java.util.UUID

class BandeiraControllerTest {

    private val bandeiraService = mockk<BandeiraService>()
    private val bandeiraPresenceService = mockk<BandeiraPresenceService>()
    private lateinit var mockMvc: MockMvc

    @BeforeEach
    fun setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(BandeiraController(bandeiraService, bandeiraPresenceService))
            .setControllerAdvice(GlobalExceptionHandler())
            .build()
    }

    @Test
    fun `list all returns 200 with bandeiras payload`() {
        val dto = BandeiraService.BandeiraDto(
            id = UUID.fromString("11111111-1111-1111-1111-111111111111"),
            name = "Liga Runners",
            slug = "liga-runners",
            category = "GRUPO",
            color = "#22C55E",
            logoUrl = null,
            description = "Equipe oficial",
            memberCount = 12,
            totalQuadras = 48,
            createdById = UUID.fromString("22222222-2222-2222-2222-222222222222"),
            createdByUsername = "captain"
        )
        every { bandeiraService.findAll() } returns listOf(dto)

        mockMvc.perform(get("/api/bandeiras"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$[0].id").value("11111111-1111-1111-1111-111111111111"))
            .andExpect(jsonPath("$[0].name").value("Liga Runners"))
            .andExpect(jsonPath("$[0].createdByUsername").value("captain"))
    }

    @Test
    fun `list all returns internal error payload on unexpected exception`() {
        every { bandeiraService.findAll() } throws RuntimeException("boom")

        mockMvc.perform(get("/api/bandeiras"))
            .andExpect(status().isInternalServerError)
            .andExpect(jsonPath("$.error").value("INTERNAL_ERROR"))
            .andExpect(jsonPath("$.message").value("An unexpected error occurred"))
    }

    @Test
    fun `presence endpoint returns weekly aggregate payload`() {
        val bandeiraId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { bandeiraPresenceService.getPresence(bandeiraId, "week") } returns
            BandeiraPresenceService.WeeklyPresenceResponse(
                bandeiraId = bandeiraId,
                period = "week",
                timezone = "America/Sao_Paulo",
                weekStart = java.time.LocalDate.parse("2026-03-16"),
                weekEnd = java.time.LocalDate.parse("2026-03-22"),
                generatedAt = java.time.Instant.parse("2026-03-16T12:00:00Z"),
                summary = BandeiraPresenceService.WeeklyPresenceSummary(
                    activeMembers = 1,
                    totalMembers = 2,
                    runsCount = 3,
                    distanceMeters = 12450.0
                ),
                members = listOf(
                    BandeiraPresenceService.WeeklyPresenceMember(
                        userId = UUID.fromString("22222222-2222-2222-2222-222222222222"),
                        username = "alice",
                        avatarUrl = null,
                        runsCount = 3,
                        distanceMeters = 12450.0,
                        lastRunAt = java.time.Instant.parse("2026-03-16T09:00:00Z"),
                        presenceState = "ACTIVE"
                    )
                )
            )

        mockMvc.perform(
            get("/api/bandeiras/$bandeiraId/presence")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.summary.activeMembers").value(1))
            .andExpect(jsonPath("$.members[0].presenceState").value("ACTIVE"))
    }
}
