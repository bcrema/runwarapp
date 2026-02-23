package com.runwar.domain.run

import com.runwar.config.UserPrincipal
import com.runwar.domain.user.User
import com.runwar.game.LoopValidationMetrics
import com.runwar.game.LoopValidator
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class RunIngestionControllerTest {

    private val runService = mockk<RunService>()
    private val controller = RunIngestionController(runService)
    private val principal = UserPrincipal(
        User(
            id = UUID.randomUUID(),
            email = "runner@example.com",
            username = "runner",
            passwordHash = "hash"
        )
    )

    @Test
    fun `submitRunWithCoordinates defaults competition mode to competitive`() {
        val capturedMode = slot<RunCompetitionMode>()
        every {
            runService.submitRunFromCoordinates(any(), any(), any(), any(), capture(capturedMode), any())
        } returns makeSubmissionResult()

        val now = Instant.now().minusSeconds(600).toEpochMilli()
        val response = controller.submitRunWithCoordinates(
            principal = principal,
            request = RunIngestionController.SubmitRunRequest(
                coordinates = listOf(
                    RunIngestionController.CoordinatePoint(-25.43, -49.27),
                    RunIngestionController.CoordinatePoint(-25.431, -49.271)
                ),
                timestamps = listOf(now, now + 300_000)
            )
        )

        assertEquals(200, response.statusCode.value())
        assertEquals(RunCompetitionMode.COMPETITIVE, capturedMode.captured)
    }

    @Test
    fun `submitRunWithCoordinates accepts training competition mode`() {
        val capturedMode = slot<RunCompetitionMode>()
        every {
            runService.submitRunFromCoordinates(any(), any(), any(), any(), capture(capturedMode), any())
        } returns makeSubmissionResult()

        val now = Instant.now().minusSeconds(600).toEpochMilli()
        val response = controller.submitRunWithCoordinates(
            principal = principal,
            request = RunIngestionController.SubmitRunRequest(
                coordinates = listOf(
                    RunIngestionController.CoordinatePoint(-25.43, -49.27),
                    RunIngestionController.CoordinatePoint(-25.431, -49.271)
                ),
                timestamps = listOf(now, now + 300_000),
                competitionMode = RunCompetitionMode.TRAINING
            )
        )

        assertEquals(200, response.statusCode.value())
        assertEquals(RunCompetitionMode.TRAINING, capturedMode.captured)
    }

    private fun makeSubmissionResult(): RunService.RunSubmissionResult {
        val runDto = RunService.RunDto(
            id = UUID.randomUUID(),
            userId = UUID.randomUUID(),
            origin = RunOrigin.IMPORT,
            status = RunStatus.VALIDATED,
            distance = 5.23,
            distanceMeters = 5230.0,
            duration = 1820,
            startTime = Instant.parse("2026-02-12T10:00:00Z"),
            endTime = Instant.parse("2026-02-12T10:30:20Z"),
            minLat = -25.44,
            minLng = -49.28,
            maxLat = -25.42,
            maxLng = -49.26,
            isLoopValid = true,
            loopDistance = 5.1,
            loopDistanceMeters = 5100.0,
            territoryAction = null,
            targetQuadraId = null,
            isValidForTerritory = false,
            fraudFlags = emptyList(),
            createdAt = Instant.parse("2026-02-12T10:30:30Z")
        )

        val loopValidation = LoopValidator.ValidationResult(
            isLoopValid = true,
            reasons = emptyList(),
            metrics = LoopValidationMetrics(
                loopDistanceMeters = 5100.0,
                loopDurationSeconds = 1820,
                closureMeters = 12.0,
                coveragePct = 0.72
            ),
            tilesCovered = listOf("8928308280fffff"),
            primaryTile = "8928308280fffff",
            fraudFlags = emptyList()
        )

        return RunService.RunSubmissionResult(
            run = runDto,
            loopValidation = loopValidation,
            territoryResult = null,
            turnResult = null
        )
    }
}
