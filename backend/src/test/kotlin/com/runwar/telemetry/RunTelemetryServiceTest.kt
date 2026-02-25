package com.runwar.telemetry

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.runwar.domain.run.CapsRemaining
import com.runwar.domain.run.CapsService
import com.runwar.domain.run.DisputeState
import com.runwar.domain.run.Run
import com.runwar.domain.run.RunCompetitionMode
import com.runwar.domain.run.RunOrigin
import com.runwar.domain.run.RunStatus
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.run.TurnResult
import com.runwar.domain.user.User
import com.runwar.game.LoopValidationMetrics
import com.runwar.game.LoopValidator
import com.runwar.game.ShieldMechanics
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

class RunTelemetryServiceTest {
    private val objectMapper = jacksonObjectMapper().findAndRegisterModules()

    @Test
    fun `recordRunTelemetry persists structured event`() {
        val repository = mockk<RunTelemetryEventRepository>()
        val saved = slot<RunTelemetryEvent>()
        every { repository.save(capture(saved)) } answers { saved.captured }

        val service = RunTelemetryService(repository, objectMapper)

        val user = createUser()
        val run = createRun(user)
        val validation =
            LoopValidator.ValidationResult(
                isLoopValid = true,
                reasons = emptyList(),
                metrics =
                    LoopValidationMetrics(
                        loopDistanceMeters = 1234.0,
                        loopDurationSeconds = 900,
                        closureMeters = 12.0,
                        coveragePct = 0.82
                    ),
                quadrasCovered = listOf("tile-1", "tile-2"),
                primaryQuadra = "tile-1",
                fraudFlags = listOf("speed_violation")
            )
        val territoryResult =
            ShieldMechanics.ActionResult(
                success = true,
                actionType = TerritoryActionType.CONQUEST,
                shieldBefore = 0,
                shieldAfter = 100,
                quadraId = "tile-1",
                cooldownUntil = Instant.parse("2024-01-01T00:00:00Z")
            )
        val capsCheck =
            CapsService.CapsCheck(
                actionsToday = 2,
                bandeiraActionsToday = 1,
                userCapReached = false,
                bandeiraCapReached = false
            )
        val turnResult =
            TurnResult(
                actionType = TerritoryActionType.CONQUEST,
                quadraId = "tile-1",
                h3Index = "tile-1",
                previousOwner = null,
                newOwner = null,
                shieldBefore = 0,
                shieldAfter = 100,
                cooldownUntil = Instant.parse("2024-01-01T00:00:00Z"),
                disputeState = DisputeState.STABLE,
                capsRemaining = CapsRemaining(userActionsRemaining = 3, bandeiraActionsRemaining = 4),
                reasons = emptyList()
            )

        service.recordRunTelemetry(run, validation, territoryResult, capsCheck, turnResult)

        assertEquals(run.id, saved.captured.runId)
        assertEquals(user.id, saved.captured.userId)
        assertEquals(RunOrigin.IMPORT, saved.captured.origin)
        assertEquals(RunStatus.VALIDATED, saved.captured.status)
        assertEquals(2, saved.captured.quadrasCoveredCount)
        assertEquals(listOf("tile-1", "tile-2"), saved.captured.quadrasCovered)
        assertEquals(listOf("speed_violation"), saved.captured.fraudFlags)

        val payloadNode = objectMapper.readTree(saved.captured.payloadJson)
        assertEquals(run.id.toString(), payloadNode["runId"].asText())
        assertEquals(run.competitionMode.name, payloadNode["competitionMode"].asText())
        assertTrue(payloadNode["loop"]["isLoopValid"].asBoolean())
    }

    @Test
    fun `buildCsv and json exports`() {
        val repository = mockk<RunTelemetryEventRepository>()
        val service = RunTelemetryService(repository, objectMapper)

        val event =
            RunTelemetryEvent(
                runId = UUID.randomUUID(),
                userId = UUID.randomUUID(),
                origin = RunOrigin.IMPORT,
                status = RunStatus.VALIDATED,
                competitionMode = RunCompetitionMode.COMPETITIVE,
                isLoopValid = true,
                loopDistanceMeters = 10.0,
                loopDurationSeconds = 600,
                closureMeters = 2.0,
                coveragePct = 0.7,
                primaryQuadraId = "tile-1",
                quadrasCoveredCount = 1,
                quadrasCovered = listOf("tile-1"),
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
                payloadJson = """{"runId":"${UUID.randomUUID()}","loop":{"isLoopValid":true}}"""
            )

        val csv = service.buildCsv(listOf(event))
        assertTrue(csv.startsWith("createdAt,runId"))
        assertTrue(csv.contains("tile-1"))

        val json = service.buildJson(listOf(event))
        assertTrue(json.startsWith("["))
        assertTrue(json.contains("\"runId\""))
    }

    private fun createUser(): User {
        val id = UUID.randomUUID()
        return User(
            id = id,
            email = "user-$id@example.com",
            username = "user-$id",
            passwordHash = "hash"
        )
    }

    private fun createRun(user: User): Run {
        return Run(
            user = user,
            origin = RunOrigin.IMPORT,
            status = RunStatus.VALIDATED,
            distance = BigDecimal.valueOf(1234.0),
            duration = 900,
            startTime = Instant.now(),
            endTime = Instant.now()
        )
    }
}
