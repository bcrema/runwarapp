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
            val distance: Double,
            val duration: Int,
            val startTime: Instant,
            val endTime: Instant,
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
                            distance = run.distance.toDouble(),
                            duration = run.duration,
                            startTime = run.startTime,
                            endTime = run.endTime,
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
    fun submitRun(user: User, gpxFile: MultipartFile): RunSubmissionResult {
        // Check daily caps
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

        // Create run record
        val run =
                Run(
                        user = user,
                        distance = BigDecimal.valueOf(parsed.totalDistance),
                        duration = parsed.totalDuration,
                        startTime = parsed.startTime,
                        endTime = parsed.endTime,
                        isLoopValid = validation.isValid,
                        loopDistance = validation.distance.let { BigDecimal.valueOf(it) },
                        closingDistance = BigDecimal.valueOf(validation.closingDistance),
                        fraudFlags = validation.fraudFlags
                )

        var territoryResult: ShieldMechanics.ActionResult? = null

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
                buildTurnResult(validation, territoryResult, user, actionsToday, bandeiraActionsToday)

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
            timestamps: List<Instant>
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

        val startTime = timestamps.firstOrNull() ?: Instant.now()
        val endTime = timestamps.lastOrNull() ?: Instant.now()
        val duration = java.time.Duration.between(startTime, endTime).seconds.toInt()

        // Create run record
        val run =
                Run(
                        user = user,
                        distance = BigDecimal.valueOf(validation.distance),
                        duration = duration,
                        startTime = startTime,
                        endTime = endTime,
                        isLoopValid = validation.isValid,
                        loopDistance = BigDecimal.valueOf(validation.distance),
                        closingDistance = BigDecimal.valueOf(validation.closingDistance),
                        fraudFlags = validation.fraudFlags
                )

        var territoryResult: ShieldMechanics.ActionResult? = null

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
                buildTurnResult(validation, territoryResult, user, actionsToday, bandeiraActionsToday)

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
            user: User,
            actionsToday: Int,
            bandeiraActionsToday: Int?
    ): TurnResult {
        val userCapReached = actionsToday >= gameProperties.userDailyActionCap
        val bandeiraCapReached =
                user.bandeira?.let { bandeira ->
                    (bandeiraActionsToday ?: 0) >= bandeira.dailyActionCap
                } ?: false
        val actionConsumed = territoryResult?.success == true
        val userRemaining =
                maxOf(
                        0,
                        gameProperties.userDailyActionCap -
                                actionsToday -
                                (if (actionConsumed) 1 else 0)
                )
        val bandeiraRemaining =
                user.bandeira?.let { bandeira ->
                    maxOf(
                            0,
                            bandeira.dailyActionCap -
                                    (bandeiraActionsToday ?: 0) -
                                    (if (actionConsumed) 1 else 0)
                    )
                }

        val reasons = mutableListOf<String>()
        if (!validation.isValid) {
            reasons.addAll(validation.failureReasons)
        }
        if (validation.fraudFlags.isNotEmpty()) {
            reasons.addAll(validation.fraudFlags.map { "fraud_flag:$it" })
        }
        if (territoryResult?.success == false && territoryResult.reason != null) {
            reasons.add(territoryResult.reason)
        }
        if (validation.isValid && userCapReached) {
            reasons.add("user_daily_action_cap_reached")
        }
        if (validation.isValid && bandeiraCapReached) {
            reasons.add("bandeira_daily_action_cap_reached")
        }
        if (validation.isValid && (territoryResult == null || territoryResult.success == false)) {
            reasons.add("valid_no_territorial_effect")
        }

        val tileId = territoryResult?.tileId ?: validation.primaryTile
        val tileSnapshot =
                if (territoryResult == null && tileId != null) {
                    tileRepository.findById(tileId).orElse(null)
                } else {
                    null
                }
        val hasPreviousOwnerInfo =
                territoryResult?.previousOwnerId != null || territoryResult?.previousOwnerType != null

        val previousOwner =
                if (hasPreviousOwnerInfo) {
                    OwnerSnapshot(territoryResult?.previousOwnerId, territoryResult?.previousOwnerType)
                } else if (tileSnapshot != null) {
                    OwnerSnapshot(tileSnapshot.ownerId, tileSnapshot.ownerType)
                } else {
                    null
                }
        val newOwner =
                if (territoryResult?.newOwnerId != null || territoryResult?.newOwnerType != null) {
                    OwnerSnapshot(territoryResult?.newOwnerId, territoryResult?.newOwnerType)
                } else if (tileSnapshot != null) {
                    OwnerSnapshot(tileSnapshot.ownerId, tileSnapshot.ownerType)
                } else {
                    null
                }

        val disputeState =
                if (tileId == null) {
                    null
                } else {
                    val ownerType =
                            territoryResult?.newOwnerType
                                    ?: territoryResult?.previousOwnerType
                                    ?: tileSnapshot?.ownerType
                    when {
                        ownerType == null -> DisputeState.NONE
                        territoryResult?.inDispute == true ->
                                DisputeState.DISPUTED
                        tileSnapshot?.isInDispute(gameProperties.disputeThreshold) == true ->
                                DisputeState.DISPUTED
                        else -> DisputeState.STABLE
                    }
                }

        return TurnResult(
                actionType = territoryResult?.actionType,
                tileId = tileId,
                h3Index = tileId,
                previousOwner = previousOwner,
                newOwner = newOwner,
                shieldBefore = territoryResult?.shieldBefore ?: tileSnapshot?.shield,
                shieldAfter = territoryResult?.shieldAfter ?: tileSnapshot?.shield,
                cooldownUntil = territoryResult?.cooldownUntil ?: tileSnapshot?.cooldownUntil,
                disputeState = disputeState,
                capsRemaining =
                        CapsRemaining(
                                userActionsRemaining = userRemaining,
                                bandeiraActionsRemaining = bandeiraRemaining
                        ),
                reasons = reasons
        )
    }
}
