package com.runwar.domain.run

import com.fasterxml.jackson.annotation.JsonAlias
import com.runwar.config.UserPrincipal
import com.runwar.game.LatLngPoint
import java.time.Instant
import java.util.UUID
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.multipart.MultipartFile

@RestController
@RequestMapping("/runs")
class RunIngestionController(private val runService: RunService) {

    data class ValidationErrorResponse(
            val message: String
    )

    data class RunIngestionResponse(
            val runId: UUID,
            val status: RunStatus
    )

    data class SubmitRunRequest(
            @JsonAlias("points")
            val coordinates: List<CoordinatePoint>,
            val timestamps: List<Long>,
            val origin: RunOrigin? = null
    )

    data class CoordinatePoint(
            val lat: Double,
            val lng: Double
    )

    @PostMapping(consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun submitRunWithGpx(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestParam("file") gpxFile: MultipartFile,
            @RequestParam(required = false, defaultValue = "IMPORT") origin: RunOrigin
    ): ResponseEntity<Any> {
        if (gpxFile.isEmpty) {
            return ResponseEntity.badRequest()
                    .body(ValidationErrorResponse("GPX file is empty."))
        }

        val result = runService.submitRun(principal.user, gpxFile, origin)
        return ResponseEntity.ok(RunIngestionResponse(result.run.id, result.run.status))
    }

    @PostMapping(consumes = [MediaType.APPLICATION_JSON_VALUE])
    fun submitRunWithCoordinates(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestBody request: SubmitRunRequest
    ): ResponseEntity<Any> {
        if (request.coordinates.size < 2) {
            return ResponseEntity.badRequest()
                    .body(ValidationErrorResponse("At least two coordinates are required."))
        }

        if (request.coordinates.size != request.timestamps.size) {
            return ResponseEntity.badRequest()
                    .body(ValidationErrorResponse("Coordinates and timestamps must have the same length."))
        }

        val hasInvalidCoordinate = request.coordinates.any { point ->
            point.lat !in -90.0..90.0 || point.lng !in -180.0..180.0
        }

        if (hasInvalidCoordinate) {
            return ResponseEntity.badRequest()
                    .body(
                            ValidationErrorResponse(
                                    "Invalid coordinate values. Latitude must be between -90 and 90, and longitude between -180 and 180."
                            )
                    )
        }
        val timestampsMillis = request.timestamps

        // Ensure timestamps are in non-decreasing chronological order
        val hasOutOfOrderTimestamps = timestampsMillis
                .windowed(size = 2, step = 1, partialWindows = false)
                .any { (prev, next) -> next < prev }
        if (hasOutOfOrderTimestamps) {
            return ResponseEntity.badRequest()
                    .body(ValidationErrorResponse("Timestamps must be in non-decreasing chronological order."))
        }

        // Ensure timestamps are within a reasonable time range relative to now
        val nowMillis = Instant.now().toEpochMilli()
        val maxFutureOffsetMillis = 7L * 24 * 60 * 60 * 1000 // 7 days
        val maxPastOffsetMillis = 365L * 24 * 60 * 60 * 1000 // 365 days

        val hasUnreasonableTimestamp = timestampsMillis.any { ts ->
            ts > nowMillis + maxFutureOffsetMillis || ts < nowMillis - maxPastOffsetMillis
        }
        if (hasUnreasonableTimestamp) {
            return ResponseEntity.badRequest()
                    .body(ValidationErrorResponse("Timestamp values are not within an acceptable range."))
        }

        val coordinates = request.coordinates.map { LatLngPoint(it.lat, it.lng) }
        val timestamps = timestampsMillis.map { Instant.ofEpochMilli(it) }
        val origin = request.origin ?: RunOrigin.IMPORT

        val result = runService.submitRunFromCoordinates(principal.user, coordinates, timestamps, origin)
        return ResponseEntity.ok(RunIngestionResponse(result.run.id, result.run.status))
    }
}
