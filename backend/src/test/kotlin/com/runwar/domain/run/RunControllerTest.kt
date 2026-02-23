package com.runwar.domain.run

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.runwar.config.UserPrincipal
import com.runwar.domain.user.User
import com.runwar.game.LoopValidationMetrics
import com.runwar.game.LoopValidator
import com.runwar.game.ShieldMechanics
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class RunControllerTest {

    private val objectMapper = jacksonObjectMapper().findAndRegisterModules()
    private val runService = mockk<RunService>()
    private val controller = RunController(runService)
    private val principal = UserPrincipal(
        User(
            id = UUID.randomUUID(),
            email = "runner@example.com",
            username = "runner",
            passwordHash = "hash"
        )
    )

    @Test
    fun `submitRunWithCoordinates returns iOS contract response shape with dailyActionsRemaining`() {
        val submissionResult = makeSubmissionResult()
        every { runService.submitRunFromCoordinates(any(), any(), any(), any(), any(), any()) } returns submissionResult
        val startSec = Instant.now().minusSeconds(900).epochSecond

        val response = controller.submitRunWithCoordinates(
            principal = principal,
            request = RunController.SubmitCoordinatesRequest(
                coordinates = listOf(
                    RunController.CoordinatePoint(-25.43, -49.27),
                    RunController.CoordinatePoint(-25.431, -49.271)
                ),
                timestamps = listOf(startSec, startSec + 900),
                mode = RunCompetitionMode.COMPETITIVE,
                targetQuadraId = "8928308280fffff"
            )
        )

        assertEquals(200, response.statusCode.value())
        assertEquals(2, response.body!!.dailyActionsRemaining)
        assertEquals(true, response.body!!.loopValidation.isValid)
        assertEquals("CONQUEST", response.body!!.territoryResult?.actionType)

        val json = objectMapper.writeValueAsString(response.body)
        val node = objectMapper.readTree(json)

        assertTrue(node.has("dailyActionsRemaining"))
        assertTrue(node.path("loopValidation").has("isValid"))
        assertTrue(node.path("loopValidation").has("failureReasons"))
        assertTrue(node.path("loopValidation").has("primaryQuadraCoverage"))
        assertTrue(node.path("territoryResult").has("shieldBefore"))
        assertTrue(node.path("run").has("distanceMeters"))
        assertTrue(node.path("run").has("loopDistanceMeters"))
        assertTrue(node.path("run").has("targetQuadraId"))
        assertTrue(node.path("turnResult").has("quadraId"))
    }

    @Test
    fun `submitRunWithCoordinates normalizes epoch seconds timestamps`() {
        val submissionResult = makeSubmissionResult()
        val capturedTimestamps = slot<List<Instant>>()
        val startSec = Instant.now().minusSeconds(900).epochSecond
        every {
            runService.submitRunFromCoordinates(any(), any(), capture(capturedTimestamps), RunOrigin.WEB, RunCompetitionMode.COMPETITIVE, null)
        } returns submissionResult

        controller.submitRunWithCoordinates(
            principal = principal,
            request = RunController.SubmitCoordinatesRequest(
                coordinates = listOf(
                    RunController.CoordinatePoint(-25.43, -49.27),
                    RunController.CoordinatePoint(-25.431, -49.271)
                ),
                timestamps = listOf(startSec, startSec + 900),
                mode = RunCompetitionMode.COMPETITIVE
            )
        )

        assertEquals(Instant.ofEpochSecond(startSec), capturedTimestamps.captured[0])
        assertEquals(Instant.ofEpochSecond(startSec + 900), capturedTimestamps.captured[1])
    }

    @Test
    fun `submitRunWithCoordinates keeps epoch milliseconds timestamps`() {
        val submissionResult = makeSubmissionResult()
        val capturedTimestamps = slot<List<Instant>>()
        val startMillis = Instant.now().minusSeconds(900).toEpochMilli()
        every {
            runService.submitRunFromCoordinates(any(), any(), capture(capturedTimestamps), RunOrigin.WEB, RunCompetitionMode.COMPETITIVE, null)
        } returns submissionResult

        controller.submitRunWithCoordinates(
            principal = principal,
            request = RunController.SubmitCoordinatesRequest(
                coordinates = listOf(
                    RunController.CoordinatePoint(-25.43, -49.27),
                    RunController.CoordinatePoint(-25.431, -49.271)
                ),
                timestamps = listOf(startMillis, startMillis + 900_000),
                mode = RunCompetitionMode.COMPETITIVE
            )
        )

        assertEquals(Instant.ofEpochMilli(startMillis), capturedTimestamps.captured[0])
        assertEquals(Instant.ofEpochMilli(startMillis + 900_000), capturedTimestamps.captured[1])
    }

    @Test
    fun `submitRunWithCoordinates rejects out of order timestamps`() {
        val nowMillis = Instant.now().toEpochMilli()
        assertThrows<IllegalArgumentException> {
            controller.submitRunWithCoordinates(
                principal = principal,
                request = RunController.SubmitCoordinatesRequest(
                    coordinates = listOf(
                        RunController.CoordinatePoint(-25.43, -49.27),
                        RunController.CoordinatePoint(-25.431, -49.271)
                    ),
                    timestamps = listOf(nowMillis + 10_000, nowMillis),
                    mode = RunCompetitionMode.COMPETITIVE
                )
            )
        }

        verify(exactly = 0) { runService.submitRunFromCoordinates(any(), any(), any(), any(), any(), any()) }
    }

    private fun makeSubmissionResult(): RunService.RunSubmissionResult {
        val runDto = RunService.RunDto(
            id = UUID.randomUUID(),
            userId = UUID.randomUUID(),
            origin = RunOrigin.IOS,
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
            territoryAction = "CONQUEST",
            targetQuadraId = "8928308280fffff",
            isValidForTerritory = true,
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

        val territoryResult = ShieldMechanics.ActionResult(
            success = true,
            actionType = TerritoryActionType.CONQUEST,
            reason = null,
            ownerChanged = true,
            shieldChange = 100,
            shieldBefore = 0,
            shieldAfter = 100,
            inDispute = false,
            tileId = "8928308280fffff"
        )

        val turnResult = TurnResult(
            actionType = TerritoryActionType.CONQUEST,
            quadraId = "8928308280fffff",
            h3Index = "8928308280fffff",
            previousOwner = null,
            newOwner = null,
            shieldBefore = 0,
            shieldAfter = 100,
            cooldownUntil = Instant.parse("2026-02-13T04:30:30Z"),
            disputeState = DisputeState.STABLE,
            capsRemaining = CapsRemaining(userActionsRemaining = 2, bandeiraActionsRemaining = null),
            reasons = emptyList()
        )

        return RunService.RunSubmissionResult(
            run = runDto,
            loopValidation = loopValidation,
            territoryResult = territoryResult,
            turnResult = turnResult
        )
    }
}
