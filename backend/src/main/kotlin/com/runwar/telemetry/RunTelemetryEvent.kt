package com.runwar.telemetry

import com.runwar.domain.run.RunOrigin
import com.runwar.domain.run.RunCompetitionMode
import com.runwar.domain.run.RunStatus
import com.runwar.domain.run.TerritoryActionType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "run_telemetry_events")
class RunTelemetryEvent(
    @Id
    val id: UUID = UUID.randomUUID(),
    @Column(name = "run_id", nullable = false)
    val runId: UUID,
    @Column(name = "user_id", nullable = false)
    val userId: UUID,
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val origin: RunOrigin,
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: RunStatus,
    @Enumerated(EnumType.STRING)
    @Column(name = "competition_mode", nullable = false)
    val competitionMode: RunCompetitionMode,
    @Column(name = "is_loop_valid", nullable = false)
    val isLoopValid: Boolean,
    @Column(name = "loop_distance_meters", nullable = false)
    val loopDistanceMeters: Double,
    @Column(name = "loop_duration_seconds", nullable = false)
    val loopDurationSeconds: Int,
    @Column(name = "closure_meters", nullable = false)
    val closureMeters: Double,
    @Column(name = "coverage_pct", nullable = false)
    val coveragePct: Double,
    @Column(name = "primary_quadra_id")
    val primaryQuadraId: String?,
    @Column(name = "quadras_covered_count", nullable = false)
    val quadrasCoveredCount: Int,
    @Column(name = "quadras_covered", nullable = false, columnDefinition = "text[]")
    val quadrasCovered: List<String>,
    @Enumerated(EnumType.STRING)
    @Column(name = "action_type")
    val actionType: TerritoryActionType?,
    @Column(name = "action_success", nullable = false)
    val actionSuccess: Boolean,
    @Column(name = "action_reason")
    val actionReason: String?,
    @Column(name = "shield_before")
    val shieldBefore: Int?,
    @Column(name = "shield_after")
    val shieldAfter: Int?,
    @Column(name = "cooldown_until")
    val cooldownUntil: Instant?,
    @Column(name = "user_cap_reached", nullable = false)
    val userCapReached: Boolean,
    @Column(name = "bandeira_cap_reached", nullable = false)
    val bandeiraCapReached: Boolean,
    @Column(name = "actions_today", nullable = false)
    val actionsToday: Int,
    @Column(name = "bandeira_actions_today")
    val bandeiraActionsToday: Int?,
    @Column(name = "user_actions_remaining", nullable = false)
    val userActionsRemaining: Int,
    @Column(name = "bandeira_actions_remaining")
    val bandeiraActionsRemaining: Int?,
    @Column(name = "fraud_flags", nullable = false, columnDefinition = "text[]")
    val fraudFlags: List<String>,
    @Column(name = "rejection_reasons", nullable = false, columnDefinition = "text[]")
    val rejectionReasons: List<String>,
    @Column(name = "payload_json", nullable = false, columnDefinition = "text")
    val payloadJson: String,
    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now()
)
