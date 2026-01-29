package com.runwar.telemetry

import java.time.Instant
import java.util.UUID
import org.springframework.data.jpa.repository.JpaRepository

interface RunTelemetryEventRepository : JpaRepository<RunTelemetryEvent, UUID> {
    fun findByCreatedAtBetweenOrderByCreatedAtAsc(
        start: Instant,
        end: Instant
    ): List<RunTelemetryEvent>
}
