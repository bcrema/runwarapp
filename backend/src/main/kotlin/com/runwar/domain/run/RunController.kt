package com.runwar.domain.run

import com.runwar.config.UserPrincipal
import com.runwar.game.LatLngPoint
import com.runwar.game.LoopValidator
import com.runwar.game.ShieldMechanics
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

    /** Submit a run via GPX file upload */
    @PostMapping(consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun submitRunWithGpx(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestParam("file") gpxFile: MultipartFile
    ): ResponseEntity<RunSubmissionResponse> {
        if (gpxFile.isEmpty) {
            throw IllegalArgumentException("GPX file is empty.")
        }

        val result = runService.submitRun(principal.user, gpxFile)
        return ResponseEntity.ok(toRunSubmissionResponse(result))
    }

    /** Submit a run via raw coordinates (from web GPS recording) */
    data class SubmitCoordinatesRequest(
            val coordinates: List<CoordinatePoint>,
            val timestamps: List<Long> // accepts epoch seconds or epoch millis
    )

    data class CoordinatePoint(val lat: Double, val lng: Double)

    @PostMapping("/coordinates")
    fun submitRunWithCoordinates(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestBody request: SubmitCoordinatesRequest
    ): ResponseEntity<RunSubmissionResponse> {
        if (request.coordinates.size < 2) {
            throw IllegalArgumentException("At least two coordinates are required.")
        }

        if (request.coordinates.size != request.timestamps.size) {
            throw IllegalArgumentException("Coordinates and timestamps must have the same length.")
        }

        val hasInvalidCoordinate = request.coordinates.any { point ->
            point.lat !in -90.0..90.0 || point.lng !in -180.0..180.0
        }
        if (hasInvalidCoordinate) {
            throw IllegalArgumentException(
                "Invalid coordinate values. Latitude must be between -90 and 90, and longitude between -180 and 180."
            )
        }

        val coordinates = request.coordinates.map { LatLngPoint(it.lat, it.lng) }
        val timestamps = RunTimestampNormalizer.normalize(request.timestamps).instants

        val result =
                runService.submitRunFromCoordinates(
                        principal.user,
                        coordinates,
                        timestamps,
                        RunOrigin.WEB
                )
        return ResponseEntity.ok(toRunSubmissionResponse(result))
    }

    /** Get current user's run history */
    @GetMapping
    fun getMyRuns(
            @AuthenticationPrincipal principal: UserPrincipal,
            @RequestParam(defaultValue = "20") limit: Int
    ): ResponseEntity<List<RunResponse>> {
        val runs = runService.getUserRuns(principal.user.id, limit)
        return ResponseEntity.ok(runs.map(::toRunResponse))
    }

    /** Get a specific run by ID */
    @GetMapping("/{id}")
    fun getRunById(@PathVariable id: UUID): ResponseEntity<RunResponse> {
        val run = runService.getRunById(id) ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(toRunResponse(run))
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

    data class RunResponse(
            val id: UUID,
            val userId: UUID,
            val origin: RunOrigin,
            val status: RunStatus,
            val distance: Double,
            val distanceMeters: Double,
            val duration: Int,
            val startTime: Instant,
            val endTime: Instant,
            val minLat: Double?,
            val minLng: Double?,
            val maxLat: Double?,
            val maxLng: Double?,
            val isLoopValid: Boolean,
            val loopDistance: Double?,
            val loopDistanceMeters: Double?,
            val territoryAction: String?,
            val targetTileId: String?,
            val isValidForTerritory: Boolean,
            val fraudFlags: List<String>,
            val createdAt: Instant
    )

    data class LoopValidationResponse(
            val isValid: Boolean,
            val distance: Double,
            val duration: Int,
            val closingDistance: Double,
            val tilesCovered: List<String>,
            val primaryTile: String?,
            val primaryTileCoverage: Double,
            val fraudFlags: List<String>,
            val failureReasons: List<String>
    )

    data class TerritoryResultResponse(
            val success: Boolean,
            val actionType: String?,
            val reason: String?,
            val ownerChanged: Boolean,
            val shieldChange: Int,
            val shieldBefore: Int,
            val shieldAfter: Int,
            val inDispute: Boolean,
            val tileId: String?
    )

    data class RunSubmissionResponse(
            val run: RunResponse,
            val loopValidation: LoopValidationResponse,
            val territoryResult: TerritoryResultResponse?,
            val turnResult: TurnResult,
            val dailyActionsRemaining: Int
    )

    private fun toRunResponse(run: RunService.RunDto): RunResponse {
            return RunResponse(
                    id = run.id,
                    userId = run.userId,
                    origin = run.origin,
                    status = run.status,
                    distance = run.distance,
                    distanceMeters = run.distanceMeters,
                    duration = run.duration,
                    startTime = run.startTime,
                    endTime = run.endTime,
                    minLat = run.minLat,
                    minLng = run.minLng,
                    maxLat = run.maxLat,
                    maxLng = run.maxLng,
                    isLoopValid = run.isLoopValid,
                    loopDistance = run.loopDistance,
                    loopDistanceMeters = run.loopDistanceMeters,
                    territoryAction = run.territoryAction,
                    targetTileId = run.targetTileId,
                    isValidForTerritory = run.isValidForTerritory,
                    fraudFlags = run.fraudFlags,
                    createdAt = run.createdAt
            )
    }

    private fun toRunSubmissionResponse(result: RunService.RunSubmissionResult): RunSubmissionResponse {
            return RunSubmissionResponse(
                    run = toRunResponse(result.run),
                    loopValidation = toLoopValidationResponse(result.loopValidation),
                    territoryResult = result.territoryResult?.let(::toTerritoryResultResponse),
                    turnResult = result.turnResult,
                    dailyActionsRemaining = result.turnResult.capsRemaining.userActionsRemaining
            )
    }

    private fun toLoopValidationResponse(validation: LoopValidator.ValidationResult): LoopValidationResponse {
            return LoopValidationResponse(
                    isValid = validation.isLoopValid,
                    distance = validation.metrics.loopDistanceMeters,
                    duration = validation.metrics.loopDurationSeconds,
                    closingDistance = validation.metrics.closureMeters,
                    tilesCovered = validation.tilesCovered,
                    primaryTile = validation.primaryTile,
                    primaryTileCoverage = validation.metrics.coveragePct,
                    fraudFlags = validation.fraudFlags,
                    failureReasons = validation.reasons
            )
    }

    private fun toTerritoryResultResponse(result: ShieldMechanics.ActionResult): TerritoryResultResponse {
            return TerritoryResultResponse(
                    success = result.success,
                    actionType = result.actionType?.name,
                    reason = result.reason,
                    ownerChanged = result.ownerChanged,
                    shieldChange = result.shieldChange,
                    shieldBefore = result.shieldBefore,
                    shieldAfter = result.shieldAfter,
                    inDispute = result.inDispute,
                    tileId = result.tileId
            )
    }
}
