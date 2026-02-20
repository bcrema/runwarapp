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
        mockMvc = MockMvcBuilders.standaloneSetup(TileController(tileService))
            .setControllerAdvice(GlobalExceptionHandler())
            .build()
    }

    @Test
    fun `get tile by id returns 404 with JSON payload when tile is missing`() {
        every { tileService.getTileById("missing-tile") } returns null

        mockMvc.perform(get("/api/tiles/missing-tile"))
            .andExpect(status().isNotFound)
            .andExpect(jsonPath("$.error").value("NOT_FOUND"))
            .andExpect(jsonPath("$.message").value("Tile not found"))
    }

    @Test
    fun `get tile by id returns tile payload when tile exists`() {
        every { tileService.getTileById("tile-1") } returns makeTileDto("tile-1")

        mockMvc.perform(get("/api/tiles/tile-1"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value("tile-1"))
            .andExpect(jsonPath("$.shield").value(80))
    }

    private fun makeTileDto(id: String): TileService.TileDto {
        return TileService.TileDto(
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
            guardianId = null,
            guardianName = null
        )
    }
}
