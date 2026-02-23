package com.runwar.domain.tile

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

class TileControllerTest {

    private val tileService = mockk<TileService>()
    private lateinit var mockMvc: MockMvc

    @BeforeEach
    fun setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(QuadraController(tileService))
            .setControllerAdvice(GlobalExceptionHandler())
            .build()
    }

    @Test
    fun `get quadra by id returns 404 with JSON payload when quadra is missing`() {
        every { tileService.getTileById("missing-quadra") } returns null

        mockMvc.perform(get("/api/quadras/missing-quadra"))
            .andExpect(status().isNotFound)
            .andExpect(jsonPath("$.error").value("NOT_FOUND"))
            .andExpect(jsonPath("$.message").value("Quadra not found"))
    }

    @Test
    fun `get quadra by id returns quadra payload when quadra exists`() {
        every { tileService.getTileById("quadra-1") } returns makeQuadraDto("quadra-1")

        mockMvc.perform(get("/api/quadras/quadra-1"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value("quadra-1"))
            .andExpect(jsonPath("$.championName").value("runner"))
            .andExpect(jsonPath("$.shield").value(80))
    }

    private fun makeQuadraDto(id: String): TileService.QuadraDto {
        return TileService.QuadraDto(
            id = id,
            lat = -25.43,
            lng = -49.27,
            boundary = listOf(
                listOf(-25.431, -49.271),
                listOf(-25.432, -49.272),
                listOf(-25.433, -49.273)
            ),
            ownerType = "SOLO",
            ownerId = null,
            ownerName = "runner",
            ownerColor = null,
            shield = 80,
            isInCooldown = false,
            isInDispute = false,
            championUserId = java.util.UUID.fromString("11111111-1111-1111-1111-111111111111"),
            championBandeiraId = null,
            championName = "runner",
            guardianId = null,
            guardianName = null
        )
    }
}
