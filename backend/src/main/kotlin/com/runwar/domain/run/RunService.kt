package com.runwar.domain.run

import com.runwar.config.GameProperties
import com.runwar.domain.quadra.QuadraRepository
import com.runwar.domain.user.User
import com.runwar.domain.user.UserRepository
import com.runwar.game.LatLngPoint
import com.runwar.game.LoopValidationFlagService
import com.runwar.game.LoopValidationInput
import com.runwar.game.LoopValidator
import com.runwar.game.ShieldMechanics
import com.runwar.geo.GpxParser
import com.runwar.telemetry.RunTelemetryService
import java.math.BigDecimal
import java.time.Instant
import java.util.*
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile

@Service
class RunService(
        private val runRepository: RunRepository,
        private val gpxParser: GpxParser,
        private val loopValidator: LoopValidator,
        private val loopValidationFlagService: LoopValidationFlagService,
        private val shieldMechanics: ShieldMechanics,
        private val gameProperties: GameProperties,
        private val quadraRepository: QuadraRepository,
        private val capsService: CapsService,
        private val runTelemetryService: RunTelemetryService,
        private val userRepository: UserRepository
) {

        data class RunDto(
                val id: UUID,
                val userId: UUID,
                val origin: RunOrigin,
                val status: RunStatus,
                val distance: Double, // kilometers (iOS compatibility)
                val distanceMeters: Double,
                val duration: Int,
                val startTime: Instant,
                val endTime: Instant,
                val minLat: Double?,
                val minLng: Double?,
                val maxLat: Double?,
                val maxLng: Double?,
                val isLoopValid: Boolean,
                val loopDistance: Double?, // kilometers (iOS compatibility)
                val loopDistanceMeters: Double?,
                val territoryAction: String?,
                val targetQuadraId: String?,
                val isValidForTerritory: Boolean,
                val fraudFlags: List<String>,
                val createdAt: Instant
        ) {
                companion object {
                        fun from(run: Run): RunDto {
                                val distanceMeters = run.distance.toDouble()
                                val loopDistanceMeters = run.loopDistance?.toDouble()

                                return RunDto(
                                        id = run.id,
                                        userId = run.user.id,
                                        origin = run.origin,
                                        status = run.status,
                                        distance = distanceMeters / 1000.0,
                                        distanceMeters = distanceMeters,
                                        duration = run.duration,
                                        startTime = run.startTime,
                                        endTime = run.endTime,
                                        minLat = run.minLat,
                                        minLng = run.minLng,
                                        maxLat = run.maxLat,
                                        maxLng = run.maxLng,
                                        isLoopValid = run.isLoopValid,
                                        loopDistance = loopDistanceMeters?.div(1000.0),
                                        loopDistanceMeters = loopDistanceMeters,
                                        territoryAction = run.territoryAction?.name,
                                        targetQuadraId = run.targetQuadra?.id,
                                        isValidForTerritory = run.isValidForTerritory,
                                        fraudFlags = run.fraudFlags,
                                        createdAt = run.createdAt
                                )
                        }
                }
        }

        data class RunSubmissionResult(
                val run: RunDto,
                val loopValidation: LoopValidator.ValidationResult,
                val territoryResult: ShieldMechanics.ActionResult?,
                val turnResult: TurnResult
        )

        /** Submit a new run from GPX file */
        @Transactional
        fun submitRun(
                user: User,
                gpxFile: MultipartFile,
                origin: RunOrigin = RunOrigin.IMPORT,
                competitionMode: RunCompetitionMode = RunCompetitionMode.COMPETITIVE,
                targetQuadraId: String? = null
        ): RunSubmissionResult {
                val managedUser = loadUserWithBandeira(user.id)

                // Check daily cap
                val capsCheck = capsService.checkCaps(managedUser)

                // Parse GPX
                val parsed = gpxParser.parse(gpxFile)

                // Validate loop
                val loopFlags = loopValidationFlagService.resolveFlags(managedUser.bandeira?.slug)
                val validation =
                        loopValidator.validate(
                                LoopValidationInput(parsed.coordinates, parsed.timestamps),
                                loopFlags
                        )
                val boundingBox = calculateBoundingBox(parsed.coordinates)
                val status = resolveStatus(validation.isLoopValid)

                // Create run record
                val run =
                        Run(
                                user = managedUser,
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
                                isLoopValid = validation.isLoopValid,
                                loopDistance =
                                        BigDecimal.valueOf(validation.metrics.loopDistanceMeters),
                                closingDistance =
                                        BigDecimal.valueOf(validation.metrics.closureMeters),
                                competitionMode = competitionMode,
                                targetQuadra = targetQuadraId?.let { quadraRepository.findById(it).orElse(null) },
                                fraudFlags = validation.fraudFlags
                        )

                var territoryResult: ShieldMechanics.ActionResult? = null
                val previousOwner =
                                validation.primaryQuadra
                                ?.let { quadraRepository.findById(it).orElse(null) }
                                ?.let { OwnerSnapshot(id = it.ownerId, type = it.ownerType) }

                // Process territory action if valid
                if (
                        competitionMode == RunCompetitionMode.COMPETITIVE &&
                                validation.isLoopValid &&
                                validation.primaryQuadra != null
                ) {
                        run.isValidForTerritory = true

                        if (!capsCheck.userCapReached && !capsCheck.bandeiraCapReached) {
                                territoryResult =
                                        shieldMechanics.processAction(
                                                validation.primaryQuadra,
                                                managedUser
                                        )
                        }

                        if (territoryResult?.success == true) {
                                run.territoryAction = territoryResult.actionType
                        }
                }

                val savedRun = runRepository.save(run)

                // Update user stats
                managedUser.totalRuns++
                managedUser.totalDistance =
                        managedUser.totalDistance.add(BigDecimal.valueOf(parsed.totalDistance))

                val turnResult =
                        buildTurnResult(
                                validation,
                                territoryResult,
                                previousOwner,
                                managedUser,
                                capsCheck.actionsToday,
                                capsCheck.bandeiraActionsToday,
                                competitionMode,
                                targetQuadraId
                        )

                runTelemetryService.recordRunTelemetry(
                        run = savedRun,
                        validation = validation,
                        territoryResult = territoryResult,
                        capsCheck = capsCheck,
                        turnResult = turnResult
                )

                return RunSubmissionResult(
                        run = RunDto.from(savedRun),
                        loopValidation = validation,
                        territoryResult = territoryResult,
                        turnResult = turnResult
                )
        }

        /** Submit a run from raw coordinates (for web GPS recording) */
        @Transactional
        fun submitRunFromCoordinates(
                user: User,
                coordinates: List<LatLngPoint>,
                timestamps: List<Instant>,
                origin: RunOrigin = RunOrigin.WEB,
                competitionMode: RunCompetitionMode = RunCompetitionMode.COMPETITIVE,
                targetQuadraId: String? = null
        ): RunSubmissionResult {
                val managedUser = loadUserWithBandeira(user.id)

                // Check daily cap
                val capsCheck = capsService.checkCaps(managedUser)

                // Validate loop
                val loopFlags = loopValidationFlagService.resolveFlags(managedUser.bandeira?.slug)
                val validation =
                        loopValidator.validate(
                                LoopValidationInput(coordinates, timestamps),
                                loopFlags
                        )
                val boundingBox = calculateBoundingBox(coordinates)
                val status = resolveStatus(validation.isLoopValid)

                val startTime = timestamps.firstOrNull() ?: Instant.now()
                val endTime = timestamps.lastOrNull() ?: Instant.now()
                val duration = java.time.Duration.between(startTime, endTime).seconds.toInt()

                // Create run record
                val run =
                        Run(
                                user = managedUser,
                                origin = origin,
                                status = status,
                                distance =
                                        BigDecimal.valueOf(validation.metrics.loopDistanceMeters),
                                duration = duration,
                                startTime = startTime,
                                endTime = endTime,
                                minLat = boundingBox.minLat,
                                minLng = boundingBox.minLng,
                                maxLat = boundingBox.maxLat,
                                maxLng = boundingBox.maxLng,
                                isLoopValid = validation.isLoopValid,
                                loopDistance =
                                        BigDecimal.valueOf(validation.metrics.loopDistanceMeters),
                                closingDistance =
                                        BigDecimal.valueOf(validation.metrics.closureMeters),
                                competitionMode = competitionMode,
                                targetQuadra = targetQuadraId?.let { quadraRepository.findById(it).orElse(null) },
                                fraudFlags = validation.fraudFlags
                        )

                var territoryResult: ShieldMechanics.ActionResult? = null
                val previousOwner =
                                validation.primaryQuadra
                                ?.let { quadraRepository.findById(it).orElse(null) }
                                ?.let { OwnerSnapshot(id = it.ownerId, type = it.ownerType) }

                if (
                        competitionMode == RunCompetitionMode.COMPETITIVE &&
                                validation.isLoopValid &&
                                validation.primaryQuadra != null
                ) {
                        run.isValidForTerritory = true

                        if (!capsCheck.userCapReached && !capsCheck.bandeiraCapReached) {
                                territoryResult =
                                        shieldMechanics.processAction(
                                                validation.primaryQuadra,
                                                managedUser
                                        )
                        }

                        if (territoryResult?.success == true) {
                                run.territoryAction = territoryResult.actionType
                        }
                }

                val savedRun = runRepository.save(run)

                // Update user stats for coordinate submissions (same behavior as GPX flow)
                managedUser.totalRuns++
                managedUser.totalDistance =
                        managedUser.totalDistance.add(BigDecimal.valueOf(validation.metrics.loopDistanceMeters))

                val turnResult =
                        buildTurnResult(
                                validation,
                                territoryResult,
                                previousOwner,
                                managedUser,
                                capsCheck.actionsToday,
                                capsCheck.bandeiraActionsToday,
                                competitionMode,
                                targetQuadraId
                        )

                runTelemetryService.recordRunTelemetry(
                        run = savedRun,
                        validation = validation,
                        territoryResult = territoryResult,
                        capsCheck = capsCheck,
                        turnResult = turnResult
                )

                return RunSubmissionResult(
                        run = RunDto.from(savedRun),
                        loopValidation = validation,
                        territoryResult = territoryResult,
                        turnResult = turnResult
                )
        }

        /** Get user's run history */
        fun getUserRuns(userId: UUID, limit: Int = 20): List<RunDto> {
                return runRepository.findByUserIdOrderByCreatedAtDesc(
                                userId,
                                PageRequest.of(0, limit)
                        )
                        .map { RunDto.from(it) }
        }

        /** Get a specific run by ID */
        fun getRunById(runId: UUID): RunDto? {
                return runRepository.findById(runId).map { RunDto.from(it) }.orElse(null)
        }

        private fun buildTurnResult(
                validation: LoopValidator.ValidationResult,
                territoryResult: ShieldMechanics.ActionResult?,
                previousOwner: OwnerSnapshot?,
                user: User,
                actionsToday: Int,
                bandeiraActionsToday: Int?,
                competitionMode: RunCompetitionMode,
                targetQuadraId: String?
        ): TurnResult {
                val quadraId = territoryResult?.quadraId ?: targetQuadraId ?: validation.primaryQuadra
                val quadra = quadraId?.let { quadraRepository.findById(it).orElse(null) }

                val disputeState =
                        when {
                                quadra == null || quadra.ownerType == null -> DisputeState.NONE
                                quadra.isInDispute(gameProperties.disputeThreshold) ->
                                        DisputeState.DISPUTED
                                else -> DisputeState.STABLE
                        }

                val actionConsumed = territoryResult?.success == true
                val userActionsRemaining =
                        (gameProperties.userDailyActionCap -
                                        actionsToday -
                                        (if (actionConsumed) 1 else 0))
                                .coerceAtLeast(0)

                val bandeiraActionsRemaining =
                        user.bandeira?.let { bandeira ->
                                val used = bandeiraActionsToday ?: 0
                                (bandeira.dailyActionCap - used - (if (actionConsumed) 1 else 0))
                                        .coerceAtLeast(0)
                        }

                val reasons = mutableListOf<String>()
                if (!validation.isLoopValid) {
                        reasons.addAll(validation.reasons)
                }
                if (
                        competitionMode == RunCompetitionMode.COMPETITIVE &&
                                validation.isLoopValid &&
                                validation.primaryQuadra == null
                ) {
                        reasons.add("no_primary_quadra")
                }

                val userCapReached = actionsToday >= gameProperties.userDailyActionCap
                val bandeiraCapReached =
                        user.bandeira?.let { bandeira ->
                                val used = bandeiraActionsToday ?: 0
                                used >= bandeira.dailyActionCap
                        }
                                ?: false

                if (competitionMode == RunCompetitionMode.COMPETITIVE && userCapReached) {
                        reasons.add("user_daily_cap_reached")
                }
                if (competitionMode == RunCompetitionMode.COMPETITIVE && bandeiraCapReached) {
                        reasons.add("bandeira_daily_cap_reached")
                }

                if (territoryResult != null && !territoryResult.success) {
                        territoryResult.reason?.let { reasons.add(it) }
                }

                return TurnResult(
                        actionType =
                                if (territoryResult?.success == true) territoryResult.actionType
                                else null,
                        quadraId = quadraId,
                        h3Index = quadraId,
                        previousOwner = previousOwner,
                        newOwner =
                                quadra?.let { OwnerSnapshot(id = it.ownerId, type = it.ownerType) },
                        shieldBefore = territoryResult?.shieldBefore,
                        shieldAfter = territoryResult?.shieldAfter,
                        cooldownUntil = quadra?.cooldownUntil,
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

        data class DailyStatusInfo(
                val userActionsUsed: Int,
                val userActionsRemaining: Int,
                val bandeiraActionsUsed: Int?,
                val bandeiraActionCap: Int?
        )

        @Transactional(readOnly = true)
        fun getDailyStatus(user: User): DailyStatusInfo {
                val managedUser = loadUserWithBandeira(user.id)
                val actionsUsed = capsService.getDailyActionCount(managedUser.id)
                val bandeiraActionsUsed =
                        managedUser.bandeira?.let { capsService.getBandeiraDailyActionCount(it.id) }

                return DailyStatusInfo(
                        userActionsUsed = actionsUsed,
                        userActionsRemaining =
                                maxOf(0, gameProperties.userDailyActionCap - actionsUsed),
                        bandeiraActionsUsed = bandeiraActionsUsed,
                        bandeiraActionCap = managedUser.bandeira?.dailyActionCap
                )
        }

        private fun loadUserWithBandeira(userId: UUID): User {
                return userRepository.findByIdWithBandeira(userId)
                        ?: throw IllegalArgumentException("User not found")
        }

        private data class BoundingBox(
                val minLat: Double,
                val minLng: Double,
                val maxLat: Double,
                val maxLng: Double
        )
}
