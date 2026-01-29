package com.runwar.telemetry

import com.fasterxml.jackson.databind.ObjectMapper
import com.runwar.domain.run.CapsService
import com.runwar.domain.run.Run
import com.runwar.domain.run.RunOrigin
import com.runwar.domain.run.RunStatus
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.run.TurnResult
import com.runwar.game.LoopValidator
import com.runwar.game.ShieldMechanics
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.time.Instant
import java.util.UUID

@Service
class RunTelemetryService(
    private val runTelemetryEventRepository: RunTelemetryEventRepository,
    private val objectMapper: ObjectMapper
) {
    private val logger = LoggerFactory.getLogger(RunTelemetryService::class.java)

    private data class RunTelemetryFields(
        val runId: UUID,
        val userId: UUID,
        val origin: RunOrigin,
        val status: RunStatus,
        val createdAt: Instant,
        val isLoopValid: Boolean,
        val loopDistanceMeters: Double,
        val loopDurationSeconds: Int,
        val closureMeters: Double,
        val coveragePct: Double,
        val primaryTileId: String?,
        val tilesCoveredCount: Int,
        val tilesCovered: List<String>,
        val actionTileId: String?,
        val actionType: TerritoryActionType?,
        val actionSuccess: Boolean,
        val actionReason: String?,
        val shieldBefore: Int?,
        val shieldAfter: Int?,
        val cooldownUntil: Instant?,
        val userCapReached: Boolean,
        val bandeiraCapReached: Boolean,
        val actionsToday: Int,
        val bandeiraActionsToday: Int?,
        val userActionsRemaining: Int,
        val bandeiraActionsRemaining: Int?,
        val fraudFlags: List<String>,
        val rejectionReasons: List<String>
    )

    data class RunTelemetryPayload(
        val runId: String,
        val userId: String,
        val origin: String,
        val status: String,
        val createdAt: Instant,
        val loop: LoopTelemetry,
        val tile: TileTelemetry,
        val action: ActionTelemetry,
        val caps: CapsTelemetry,
        val antifraud: AntiFraudTelemetry,
        val rejectionReasons: List<String>
    )

    data class LoopTelemetry(
        val isLoopValid: Boolean,
        val loopDistanceMeters: Double,
        val loopDurationSeconds: Int,
        val closureMeters: Double,
        val coveragePct: Double
    )

    data class TileTelemetry(
        val primaryTileId: String?,
        val tilesCoveredCount: Int,
        val tilesCovered: List<String>
    )

    data class ActionTelemetry(
        val tileId: String?,
        val actionType: String?,
        val success: Boolean,
        val reason: String?,
        val shieldBefore: Int?,
        val shieldAfter: Int?,
        val cooldownUntil: Instant?
    )

    data class CapsTelemetry(
        val actionsToday: Int,
        val bandeiraActionsToday: Int?,
        val userCapReached: Boolean,
        val bandeiraCapReached: Boolean,
        val userActionsRemaining: Int,
        val bandeiraActionsRemaining: Int?
    )

    data class AntiFraudTelemetry(
        val flags: List<String>
    )

    fun recordRunTelemetry(
        run: Run,
        validation: LoopValidator.ValidationResult,
        territoryResult: ShieldMechanics.ActionResult?,
        capsCheck: CapsService.CapsCheck,
        turnResult: TurnResult
    ): RunTelemetryEvent {
        val fields = buildFields(run, validation, territoryResult, capsCheck, turnResult)
        val payload = buildPayload(fields)
        val payloadJson = objectMapper.writeValueAsString(payload)
        val event = buildEvent(fields, payloadJson)

        val saved = runTelemetryEventRepository.save(event)
        logger.info("run_telemetry_event={}", payloadJson)
        return saved
    }

    fun fetchEvents(start: Instant, end: Instant): List<RunTelemetryEvent> {
        return runTelemetryEventRepository.findByCreatedAtBetweenOrderByCreatedAtAsc(start, end)
    }

    fun buildJson(events: List<RunTelemetryEvent>): String {
        return events.joinToString(prefix = "[", postfix = "]") { it.payloadJson }
    }

    fun buildCsv(events: List<RunTelemetryEvent>): String {
        val header =
            listOf(
                "createdAt",
                "runId",
                "userId",
                "origin",
                "status",
                "isLoopValid",
                "loopDistanceMeters",
                "loopDurationSeconds",
                "closureMeters",
                "coveragePct",
                "primaryTileId",
                "tilesCoveredCount",
                "tilesCovered",
                "actionType",
                "actionSuccess",
                "actionReason",
                "shieldBefore",
                "shieldAfter",
                "cooldownUntil",
                "userCapReached",
                "bandeiraCapReached",
                "actionsToday",
                "bandeiraActionsToday",
                "userActionsRemaining",
                "bandeiraActionsRemaining",
                "fraudFlags",
                "rejectionReasons"
            )
        val builder = StringBuilder()
        builder.append(header.joinToString(",")).append("\n")
        events.forEach { event ->
            val row =
                listOf(
                    event.createdAt,
                    event.runId,
                    event.userId,
                    event.origin.name,
                    event.status.name,
                    event.isLoopValid,
                    event.loopDistanceMeters,
                    event.loopDurationSeconds,
                    event.closureMeters,
                    event.coveragePct,
                    event.primaryTileId,
                    event.tilesCoveredCount,
                    event.tilesCovered.joinToString("|"),
                    event.actionType?.name,
                    event.actionSuccess,
                    event.actionReason,
                    event.shieldBefore,
                    event.shieldAfter,
                    event.cooldownUntil,
                    event.userCapReached,
                    event.bandeiraCapReached,
                    event.actionsToday,
                    event.bandeiraActionsToday,
                    event.userActionsRemaining,
                    event.bandeiraActionsRemaining,
                    event.fraudFlags.joinToString("|"),
                    event.rejectionReasons.joinToString("|")
                ).joinToString(",") { toCsv(it) }
            builder.append(row).append("\n")
        }
        return builder.toString()
    }

    private fun toCsv(value: Any?): String {
        if (value == null) {
            return ""
        }
        val raw = value.toString()
        val needsEscaping = raw.contains(",") || raw.contains("\"") || raw.contains("\n")
        if (!needsEscaping) {
            return raw
        }
        val escaped = raw.replace("\"", "\"\"")
        return "\"$escaped\""
    }

    private fun buildFields(
        run: Run,
        validation: LoopValidator.ValidationResult,
        territoryResult: ShieldMechanics.ActionResult?,
        capsCheck: CapsService.CapsCheck,
        turnResult: TurnResult
    ): RunTelemetryFields {
        return RunTelemetryFields(
            runId = run.id,
            userId = run.user.id,
            origin = run.origin,
            status = run.status,
            createdAt = run.createdAt,
            isLoopValid = validation.isLoopValid,
            loopDistanceMeters = validation.metrics.loopDistanceMeters,
            loopDurationSeconds = validation.metrics.loopDurationSeconds,
            closureMeters = validation.metrics.closureMeters,
            coveragePct = validation.metrics.coveragePct,
            primaryTileId = validation.primaryTile,
            tilesCoveredCount = validation.tilesCovered.size,
            tilesCovered = validation.tilesCovered,
            actionTileId = territoryResult?.tileId ?: validation.primaryTile,
            actionType = territoryResult?.actionType,
            actionSuccess = territoryResult?.success == true,
            actionReason = territoryResult?.reason,
            shieldBefore = territoryResult?.shieldBefore,
            shieldAfter = territoryResult?.shieldAfter,
            cooldownUntil = territoryResult?.cooldownUntil,
            userCapReached = capsCheck.userCapReached,
            bandeiraCapReached = capsCheck.bandeiraCapReached,
            actionsToday = capsCheck.actionsToday,
            bandeiraActionsToday = capsCheck.bandeiraActionsToday,
            userActionsRemaining = turnResult.capsRemaining.userActionsRemaining,
            bandeiraActionsRemaining = turnResult.capsRemaining.bandeiraActionsRemaining,
            fraudFlags = validation.fraudFlags,
            rejectionReasons = turnResult.reasons
        )
    }

    private fun buildPayload(fields: RunTelemetryFields): RunTelemetryPayload {
        return RunTelemetryPayload(
            runId = fields.runId.toString(),
            userId = fields.userId.toString(),
            origin = fields.origin.name,
            status = fields.status.name,
            createdAt = fields.createdAt,
            loop =
                LoopTelemetry(
                    isLoopValid = fields.isLoopValid,
                    loopDistanceMeters = fields.loopDistanceMeters,
                    loopDurationSeconds = fields.loopDurationSeconds,
                    closureMeters = fields.closureMeters,
                    coveragePct = fields.coveragePct
                ),
            tile =
                TileTelemetry(
                    primaryTileId = fields.primaryTileId,
                    tilesCoveredCount = fields.tilesCoveredCount,
                    tilesCovered = fields.tilesCovered
                ),
            action =
                ActionTelemetry(
                    tileId = fields.actionTileId,
                    actionType = fields.actionType?.name,
                    success = fields.actionSuccess,
                    reason = fields.actionReason,
                    shieldBefore = fields.shieldBefore,
                    shieldAfter = fields.shieldAfter,
                    cooldownUntil = fields.cooldownUntil
                ),
            caps =
                CapsTelemetry(
                    actionsToday = fields.actionsToday,
                    bandeiraActionsToday = fields.bandeiraActionsToday,
                    userCapReached = fields.userCapReached,
                    bandeiraCapReached = fields.bandeiraCapReached,
                    userActionsRemaining = fields.userActionsRemaining,
                    bandeiraActionsRemaining = fields.bandeiraActionsRemaining
                ),
            antifraud = AntiFraudTelemetry(flags = fields.fraudFlags),
            rejectionReasons = fields.rejectionReasons
        )
    }

    private fun buildEvent(
        fields: RunTelemetryFields,
        payloadJson: String
    ): RunTelemetryEvent {
        return RunTelemetryEvent(
            runId = fields.runId,
            userId = fields.userId,
            origin = fields.origin,
            status = fields.status,
            isLoopValid = fields.isLoopValid,
            loopDistanceMeters = fields.loopDistanceMeters,
            loopDurationSeconds = fields.loopDurationSeconds,
            closureMeters = fields.closureMeters,
            coveragePct = fields.coveragePct,
            primaryTileId = fields.primaryTileId,
            tilesCoveredCount = fields.tilesCoveredCount,
            tilesCovered = fields.tilesCovered,
            actionType = fields.actionType,
            actionSuccess = fields.actionSuccess,
            actionReason = fields.actionReason,
            shieldBefore = fields.shieldBefore,
            shieldAfter = fields.shieldAfter,
            cooldownUntil = fields.cooldownUntil,
            userCapReached = fields.userCapReached,
            bandeiraCapReached = fields.bandeiraCapReached,
            actionsToday = fields.actionsToday,
            bandeiraActionsToday = fields.bandeiraActionsToday,
            userActionsRemaining = fields.userActionsRemaining,
            bandeiraActionsRemaining = fields.bandeiraActionsRemaining,
            fraudFlags = fields.fraudFlags,
            rejectionReasons = fields.rejectionReasons,
            payloadJson = payloadJson,
            createdAt = fields.createdAt
        )
    }
}
