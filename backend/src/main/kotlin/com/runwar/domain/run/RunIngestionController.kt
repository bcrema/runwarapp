package com.runwar.domain.run

import com.fasterxml.jackson.annotation.JsonAlias
import com.runwar.config.UserPrincipal
import com.runwar.game.LatLngPoint
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

        val normalizedTimestamps = try {
            RunTimestampNormalizer.normalize(request.timestamps)
        } catch (e: IllegalArgumentException) {
            return ResponseEntity.badRequest()
                .body(ValidationErrorResponse(e.message ?: "Invalid timestamps."))
        }

        val coordinates = request.coordinates.map { LatLngPoint(it.lat, it.lng) }
        val timestamps = normalizedTimestamps.instants
        val origin = request.origin ?: RunOrigin.IMPORT

        val result =
            runService.submitRunFromCoordinates(
                principal.user,
                coordinates,
                timestamps,
                origin,
                RunCompetitionMode.COMPETITIVE,
                null
            )
        return ResponseEntity.ok(RunIngestionResponse(result.run.id, result.run.status))
    }
}
