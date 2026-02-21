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
    private lateinit var mockMvc: MockMvc

    @BeforeEach
    fun setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(BandeiraController(bandeiraService))
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
            totalTiles = 48,
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
}
