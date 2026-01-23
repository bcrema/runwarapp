package com.runwar.domain.run

import com.runwar.config.GameProperties
import com.runwar.domain.territory.TerritoryActionRepository
import com.runwar.domain.tile.TileRepository
import com.runwar.domain.user.User
import com.runwar.game.LatLngPoint
import com.runwar.game.LoopValidator
import com.runwar.game.ShieldMechanics
import com.runwar.geo.GpxParser
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.*
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile

@Service
class RunService(
        private val runRepository: RunRepository,
        private val territoryActionRepository: TerritoryActionRepository,
        private val gpxParser: GpxParser,
        private val loopValidator: LoopValidator,
        private val shieldMechanics: ShieldMechanics,
        private val gameProperties: GameProperties,
        private val tileRepository: TileRepository
) {

    data class RunDto(
            val id: UUID,
            val userId: UUID,
            val origin: RunOrigin,
            val status: RunStatus,
            val distance: Double,
            val duration: Int,
            val startTime: Instant,
            val endTime: Instant,
            val minLat: Double?,
            val minLng: Double?,
            val maxLat: Double?,
            val maxLng: Double?,
            val isLoopValid: Boolean,
            val loopDistance: Double?,
            val territoryAction: String?,
            val targetTileId: String?,
            val isValidForTerritory: Boolean,
            val fraudFlags: List<String>,
            val createdAt: Instant
    ) {
        companion object {
            fun from(run: Run) =
                    RunDto(
                            id = run.id,
                            userId = run.user.id,
                            origin = run.origin,
                            status = run.status,
                            distance = run.distance.toDouble(),
                            duration = run.duration,
                            startTime = run.startTime,
                            endTime = run.endTime,
                            minLat = run.minLat,
                            minLng = run.minLng,
                            maxLat = run.maxLat,
                            maxLng = run.maxLng,
                            isLoopValid = run.isLoopValid,
                            loopDistance = run.loopDistance?.toDouble(),
                            territoryAction = run.territoryAction?.name,
                            targetTileId = run.targetTile?.id,
                            isValidForTerritory = run.isValidForTerritory,
                            fraudFlags = run.fraudFlags,
                            createdAt = run.createdAt
                    )
        }
    }

    data class RunSubmissionResult(
            val run: RunDto,
            val loopValidation: LoopValidator.ValidationResult,
            val turnResult: TurnResult
    )

    /** Submit a new run from GPX file */
    @Transactional
    fun submitRun(
            user: User,
            gpxFile: MultipartFile,
            origin: RunOrigin = RunOrigin.IMPORT
    ): RunSubmissionResult {
        // Check daily cap
        val actionsToday = getDailyActionCount(user)
        val userCapReached = actionsToday >= gameProperties.userDailyActionCap
        val bandeiraActionsToday = user.bandeira?.let { getBandeiraDailyActionCount(it.id) }
        val bandeiraCapReached =
                user.bandeira?.let { bandeira ->
                    (bandeiraActionsToday ?: 0) >= bandeira.dailyActionCap
                } ?: false

        // Parse GPX
        val parsed = gpxParser.parse(gpxFile)

        // Validate loop
        val validation = loopValidator.validate(parsed.coordinates, parsed.timestamps)
        val boundingBox = calculateBoundingBox(parsed.coordinates)
        val status = resolveStatus(validation.isValid)

        // Create run record
        val run =
                Run(
                        user = user,
                        origin = origin,
                        status = status,
                        distance = BigDecimal.valueOf(parsed.totalDistance),
                        duration = parsed.totalDuration,
                        startTime = parsed.startTime,
                        endTime = parsed.endTime,
                        minLat = boundingBox.minLat,
                        minLng = boundingBox.minLng,
                        maxLat = boundingBox.maxLat,
                        maxLng = boundingBox.maxLng,
                        isLoopValid = validation.isValid,
                        loopDistance = validation.distance.let { BigDecimal.valueOf(it) },
                        closingDistance = BigDecimal.valueOf(validation.closingDistance),
                        fraudFlags = validation.fraudFlags
                )

        var territoryResult: ShieldMechanics.ActionResult? = null
        val previousOwner =
                validation.primaryTile
                        ?.let { tileRepository.findById(it).orElse(null) }
                        ?.let { OwnerSnapshot(id = it.ownerId, type = it.ownerType) }

        // Process territory action if valid
        if (validation.isValid && validation.primaryTile != null) {
            run.isValidForTerritory = true

            if (!userCapReached && !bandeiraCapReached) {
                territoryResult = shieldMechanics.processAction(validation.primaryTile, user)
            }

            if (territoryResult?.success == true) {
                run.territoryAction = territoryResult.actionType
                run.targetTile = null // Will be set by repository
            }
        }

        val savedRun = runRepository.save(run)

        // Update user stats
        user.totalRuns++
        user.totalDistance = user.totalDistance.add(BigDecimal.valueOf(parsed.totalDistance))

        val turnResult =
                buildTurnResult(
                        validation,
                        territoryResult,
                        previousOwner,
                        user,
                        actionsToday,
                        bandeiraActionsToday
                )

        return RunSubmissionResult(
                run = RunDto.from(savedRun),
                loopValidation = validation,
                turnResult = turnResult
        )
    }

    /** Submit a run from raw coordinates (for web GPS recording) */
    @Transactional
    fun submitRunFromCoordinates(
            user: User,
            coordinates: List<LatLngPoint>,
            timestamps: List<Instant>,
            origin: RunOrigin = RunOrigin.WEB
    ): RunSubmissionResult {
        // Check daily cap
        val actionsToday = getDailyActionCount(user)
        val userCapReached = actionsToday >= gameProperties.userDailyActionCap
        val bandeiraActionsToday = user.bandeira?.let { getBandeiraDailyActionCount(it.id) }
        val bandeiraCapReached =
                user.bandeira?.let { bandeira ->
                    (bandeiraActionsToday ?: 0) >= bandeira.dailyActionCap
                } ?: false

        // Validate loop
        val validation = loopValidator.validate(coordinates, timestamps)
        val boundingBox = calculateBoundingBox(coordinates)
        val status = resolveStatus(validation.isValid)

        val startTime = timestamps.firstOrNull() ?: Instant.now()
        val endTime = timestamps.lastOrNull() ?: Instant.now()
        val duration = java.time.Duration.between(startTime, endTime).seconds.toInt()

        // Create run record
        val run =
                Run(
                        user = user,
                        origin = origin,
                        status = status,
                        distance = BigDecimal.valueOf(validation.distance),
                        duration = duration,
                        startTime = startTime,
                        endTime = endTime,
                        minLat = boundingBox.minLat,
                        minLng = boundingBox.minLng,
                        maxLat = boundingBox.maxLat,
                        maxLng = boundingBox.maxLng,
                        isLoopValid = validation.isValid,
                        loopDistance = BigDecimal.valueOf(validation.distance),
                        closingDistance = BigDecimal.valueOf(validation.closingDistance),
                        fraudFlags = validation.fraudFlags
                )

        var territoryResult: ShieldMechanics.ActionResult? = null
        val previousOwner =
                validation.primaryTile
                        ?.let { tileRepository.findById(it).orElse(null) }
                        ?.let { OwnerSnapshot(id = it.ownerId, type = it.ownerType) }

        if (validation.isValid && validation.primaryTile != null) {
            run.isValidForTerritory = true

            if (!userCapReached && !bandeiraCapReached) {
                territoryResult = shieldMechanics.processAction(validation.primaryTile, user)
            }

            if (territoryResult?.success == true) {
                run.territoryAction = territoryResult.actionType
            }
        }

        val savedRun = runRepository.save(run)

        val turnResult =
                buildTurnResult(
                        validation,
                        territoryResult,
                        previousOwner,
                        user,
                        actionsToday,
                        bandeiraActionsToday
                )

        return RunSubmissionResult(
                run = RunDto.from(savedRun),
                loopValidation = validation,
                turnResult = turnResult
        )
    }

    /** Get user's run history */
    fun getUserRuns(userId: UUID, limit: Int = 20): List<RunDto> {
        return runRepository.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, limit))
                .map { RunDto.from(it) }
    }

    /** Get a specific run by ID */
    fun getRunById(runId: UUID): RunDto? {
        return runRepository.findById(runId).map { RunDto.from(it) }.orElse(null)
    }

    /** Get the count of territory actions today for a user */
    fun getDailyActionCount(user: User): Int {
        val startOfDay = LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant()
        return territoryActionRepository.countUserActionsToday(user.id, startOfDay)
    }

    /** Get the count of territory actions today for a bandeira */
    fun getBandeiraDailyActionCount(bandeiraId: UUID): Int {
        val startOfDay = LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant()
        return territoryActionRepository.countBandeiraActionsToday(bandeiraId, startOfDay)
    }

    private fun buildTurnResult(
            validation: LoopValidator.ValidationResult,
            territoryResult: ShieldMechanics.ActionResult?,
            previousOwner: OwnerSnapshot?,
            user: User,
            actionsToday: Int,
            bandeiraActionsToday: Int?
    ): TurnResult {
        val tileId = territoryResult?.tileId ?: validation.primaryTile
        val tile = tileId?.let { tileRepository.findById(it).orElse(null) }

        val disputeState =
                when {
                    tile == null || tile.ownerType == null -> DisputeState.NONE
                    tile.isInDispute(gameProperties.disputeThreshold) -> DisputeState.DISPUTED
                    else -> DisputeState.STABLE
                }

        val actionConsumed = territoryResult?.success == true
        val userActionsRemaining =
                (gameProperties.userDailyActionCap - actionsToday - (if (actionConsumed) 1 else 0))
                        .coerceAtLeast(0)

        val bandeiraActionsRemaining =
                user.bandeira?.let { bandeira ->
                    val used = bandeiraActionsToday ?: 0
                    (bandeira.dailyActionCap - used - (if (actionConsumed) 1 else 0)).coerceAtLeast(0)
                }

        val reasons = mutableListOf<String>()
        if (!validation.isValid) {
            reasons.addAll(validation.failureReasons)
        }
        if (validation.isValid && validation.primaryTile == null) {
            reasons.add("no_primary_tile")
        }

        val userCapReached = actionsToday >= gameProperties.userDailyActionCap
        val bandeiraCapReached =
                user.bandeira?.let { bandeira ->
                    val used = bandeiraActionsToday ?: 0
                    used >= bandeira.dailyActionCap
                } ?: false

        if (userCapReached) reasons.add("user_daily_cap_reached")
        if (bandeiraCapReached) reasons.add("bandeira_daily_cap_reached")

        if (territoryResult != null && !territoryResult.success) {
            territoryResult.reason?.let { reasons.add(it) }
        }

        return TurnResult(
                actionType = if (territoryResult?.success == true) territoryResult.actionType else null,
                tileId = tileId,
                h3Index = tileId,
                previousOwner = previousOwner,
                newOwner =
                        tile?.let { OwnerSnapshot(id = it.ownerId, type = it.ownerType) },
                shieldBefore = territoryResult?.shieldBefore,
                shieldAfter = territoryResult?.shieldAfter,
                cooldownUntil = tile?.cooldownUntil,
                disputeState = disputeState,
                capsRemaining =
                        CapsRemaining(
                                userActionsRemaining = userActionsRemaining,
                                bandeiraActionsRemaining = bandeiraActionsRemaining
                        ),
                reasons = reasons
        )
    }

    private fun resolveStatus(isValid: Boolean): RunStatus {
        return if (isValid) RunStatus.VALIDATED else RunStatus.REJECTED
    }

    private fun calculateBoundingBox(coordinates: List<LatLngPoint>): BoundingBox {
        val minLat = coordinates.minOf { it.lat }
        val minLng = coordinates.minOf { it.lng }
        val maxLat = coordinates.maxOf { it.lat }
        val maxLng = coordinates.maxOf { it.lng }
        return BoundingBox(minLat, minLng, maxLat, maxLng)
    }

    private data class BoundingBox(
            val minLat: Double,
            val minLng: Double,
            val maxLat: Double,
            val maxLng: Double
    )
}
