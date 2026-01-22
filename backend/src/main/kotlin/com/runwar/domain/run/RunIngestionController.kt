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
    ): ResponseEntity<RunIngestionResponse> {
        if (gpxFile.isEmpty) {
            return ResponseEntity.badRequest().build()
        }

        val result = runService.submitRun(principal.user, gpxFile, origin)
        return ResponseEntity.ok(RunIngestionResponse(result.run.id, result.run.status))
    }

    @PostMapping(consumes = [MediaType.APPLICATION_JSON_VALUE])
    fun submitRunWithCoordinates(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestBody request: SubmitRunRequest
    ): ResponseEntity<RunIngestionResponse> {
        if (request.coordinates.size < 2) {
            return ResponseEntity.badRequest().build()
        }

        if (request.coordinates.size != request.timestamps.size) {
            return ResponseEntity.badRequest().build()
        }

        val coordinates = request.coordinates.map { LatLngPoint(it.lat, it.lng) }
        val timestamps = request.timestamps.map { Instant.ofEpochMilli(it) }
        val origin = request.origin ?: RunOrigin.IMPORT

        val result = runService.submitRunFromCoordinates(principal.user, coordinates, timestamps, origin)
        return ResponseEntity.ok(RunIngestionResponse(result.run.id, result.run.status))
    }
}
