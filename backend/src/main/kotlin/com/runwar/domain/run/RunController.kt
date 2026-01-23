package com.runwar.domain.run

import com.runwar.config.UserPrincipal
import com.runwar.game.LatLngPoint
import java.time.Instant
import java.util.*
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile

@RestController
@RequestMapping(value = ["/api/runs", "/runs"])
class RunController(private val runService: RunService) {

    data class ValidationErrorResponse(val message: String)

    /** Submit a run via GPX file upload */
    @PostMapping(consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun submitRunWithGpx(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestParam("file") gpxFile: MultipartFile
    ): ResponseEntity<Any> {
        if (gpxFile.isEmpty) {
            return ResponseEntity.badRequest().body(ValidationErrorResponse("GPX file is empty."))
        }

        val result = runService.submitRun(principal.user, gpxFile)
        return ResponseEntity.ok(result)
    }

    /** Submit a run via raw coordinates (from web GPS recording) */
    data class SubmitCoordinatesRequest(
            val coordinates: List<CoordinatePoint>,
            val timestamps: List<Long> // epoch millis
    )

    data class CoordinatePoint(val lat: Double, val lng: Double)

    @PostMapping("/coordinates")
    fun submitRunWithCoordinates(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestBody request: SubmitCoordinatesRequest
    ): ResponseEntity<Any> {
        if (request.coordinates.size < 2) {
            return ResponseEntity.badRequest()
                    .body(ValidationErrorResponse("At least two coordinates are required."))
        }

        if (request.coordinates.size != request.timestamps.size) {
            return ResponseEntity.badRequest()
                    .body(
                            ValidationErrorResponse(
                                    "Coordinates and timestamps must have the same length."
                            )
                    )
        }

        val coordinates = request.coordinates.map { LatLngPoint(it.lat, it.lng) }
        val timestamps = request.timestamps.map { Instant.ofEpochMilli(it) }

        val result =
                runService.submitRunFromCoordinates(
                        principal.user,
                        coordinates,
                        timestamps,
                        RunOrigin.WEB
                )
        return ResponseEntity.ok(result)
    }

    /** Get current user's run history */
    @GetMapping
    fun getMyRuns(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestParam(defaultValue = "20") limit: Int
    ): ResponseEntity<List<RunService.RunDto>> {
        val runs = runService.getUserRuns(principal.user.id, limit)
        return ResponseEntity.ok(runs)
    }

    /** Get a specific run by ID */
    @GetMapping("/{id}")
    fun getRunById(@PathVariable id: UUID): ResponseEntity<RunService.RunDto> {
        val run = runService.getRunById(id) ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(run)
    }

    /** Get daily action status for current user */
    @GetMapping("/daily-status")
    fun getDailyStatus(
            @AuthenticationPrincipal principal: UserPrincipal
    ): ResponseEntity<DailyStatusResponse> {
        val status = runService.getDailyStatus(principal.user)

        return ResponseEntity.ok(
                DailyStatusResponse(
                        userActionsUsed = status.userActionsUsed,
                        userActionsRemaining = status.userActionsRemaining,
                        bandeiraActionsUsed = status.bandeiraActionsUsed,
                        bandeiraActionCap = status.bandeiraActionCap
                )
        )
    }

    data class DailyStatusResponse(
            val userActionsUsed: Int,
            val userActionsRemaining: Int,
            val bandeiraActionsUsed: Int?,
            val bandeiraActionCap: Int?
    )
}
