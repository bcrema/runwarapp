package com.runwar.telemetry

import com.runwar.config.UserPrincipal
import com.runwar.domain.user.UserRole
import java.time.Instant
import java.time.temporal.ChronoUnit
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.server.ResponseStatusException
import org.springframework.http.HttpStatus

@RestController
@RequestMapping("/api/admin/telemetry")
class RunTelemetryController(
    private val runTelemetryService: RunTelemetryService
) {
    @GetMapping("/runs")
    fun exportRuns(
        @AuthenticationPrincipal principal: UserPrincipal,
        @RequestParam(defaultValue = "json") format: String,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
        from: Instant?,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
        to: Instant?
    ): ResponseEntity<String> {
        if (principal.user.role != UserRole.ADMIN) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Admin access required")
        }

        val start = from ?: Instant.now().minus(1, ChronoUnit.DAYS)
        val end = to ?: Instant.now()
        val events = runTelemetryService.fetchEvents(start, end)

        return when (format.lowercase()) {
            "csv" -> {
                val csv = runTelemetryService.buildCsv(events)
                ResponseEntity.ok()
                    .contentType(MediaType("text", "csv"))
                    .header("Content-Disposition", "attachment; filename=run-telemetry.csv")
                    .body(csv)
            }
            "json" -> {
                val json = runTelemetryService.buildJson(events)
                ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(json)
            }
            else -> throw ResponseStatusException(HttpStatus.BAD_REQUEST, "Unsupported format")
        }
    }
}
