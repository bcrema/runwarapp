package com.runwar.game

import com.runwar.config.GameProperties
import com.runwar.domain.bandeira.BandeiraRepository
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.territory.TerritoryAction
import com.runwar.domain.territory.TerritoryActionRepository
import com.runwar.domain.quadra.OwnerType
import com.runwar.domain.quadra.Quadra
import com.runwar.domain.quadra.QuadraRepository
import com.runwar.domain.user.User
import com.runwar.domain.user.UserRepository
import com.runwar.notification.NotificationService
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.*

@Service
class ShieldMechanics(
    private val gameProperties: GameProperties,
    private val quadraRepository: QuadraRepository,
    private val territoryActionRepository: TerritoryActionRepository,
    private val userRepository: UserRepository,
    private val bandeiraRepository: BandeiraRepository,
    private val notificationService: NotificationService,
    private val h3GridService: H3GridService
) {
    
    data class ActionResult(
        val success: Boolean,
        val actionType: TerritoryActionType? = null,
        val reason: String? = null,
        val ownerChanged: Boolean = false,
        val previousOwnerId: UUID? = null,
        val previousOwnerType: OwnerType? = null,
        val newOwnerId: UUID? = null,
        val newOwnerType: OwnerType? = null,
        val shieldChange: Int = 0,
        val shieldBefore: Int = 0,
        val shieldAfter: Int = 0,
        val inDispute: Boolean = false,
        val quadraId: String? = null,
        val cooldownUntil: Instant? = null
    ) {
        companion object {
            fun failure(reason: String) = ActionResult(success = false, reason = reason)

            fun failureWithQuadra(reason: String, quadra: Quadra, disputeThreshold: Int) =
                ActionResult(
                    success = false,
                    reason = reason,
                    previousOwnerId = quadra.ownerId,
                    previousOwnerType = quadra.ownerType,
                    newOwnerId = quadra.ownerId,
                    newOwnerType = quadra.ownerType,
                    shieldBefore = quadra.shield,
                    shieldAfter = quadra.shield,
                    inDispute = quadra.isInDispute(disputeThreshold),
                    quadraId = quadra.id,
                    cooldownUntil = quadra.cooldownUntil
                )
        }
    }
    
    /**
     * Determine the appropriate action type for a user on a quadra
     */
    fun determineActionType(quadra: Quadra, user: User): TerritoryActionType? {
        return when {
            quadra.isNeutral() -> TerritoryActionType.CONQUEST
            isOwner(quadra, user) -> TerritoryActionType.DEFENSE
            else -> TerritoryActionType.ATTACK
        }
    }
    
    /**
     * Process a territory action (conquest, attack, or defense)
     */
    @Transactional
    fun processAction(
        quadraId: String,
        user: User,
        providedActionType: TerritoryActionType? = null
    ): ActionResult {
        // Find or create quadra
        val quadra = quadraRepository.findById(quadraId).orElseGet {
            createQuadra(quadraId)
        }
        
        // Determine action type if not provided
        val actionType = providedActionType ?: determineActionType(quadra, user)
            ?: return ActionResult.failureWithQuadra(
                "cannot_determine_action",
                quadra,
                gameProperties.disputeThreshold
            )
        
        // Validate action is allowed
        val validationError = validateAction(quadra, user, actionType)
        if (validationError != null) {
            return ActionResult.failureWithQuadra(
                validationError,
                quadra,
                gameProperties.disputeThreshold
            )
        }
        
        val bandeira = user.bandeira
        val shieldBefore = quadra.shield
        var shieldChange = 0
        var ownerChanged = false
        val previousOwnerId = quadra.ownerId
        val previousOwnerType = quadra.ownerType
        var newOwnerId = quadra.ownerId
        var newOwnerType = quadra.ownerType
        
        when (actionType) {
            TerritoryActionType.CONQUEST -> {
                shieldChange = gameProperties.conquestInitialShield
                newOwnerId = bandeira?.id ?: user.id
                newOwnerType = if (bandeira != null) OwnerType.BANDEIRA else OwnerType.SOLO
                ownerChanged = true
            }
            
            TerritoryActionType.ATTACK -> {
                shieldChange = -gameProperties.attackDamage
                val projectedShield = quadra.shield + shieldChange
                
                if (projectedShield <= 0 && !quadra.isInCooldown()) {
                    // Transfer ownership
                    newOwnerId = bandeira?.id ?: user.id
                    newOwnerType = if (bandeira != null) OwnerType.BANDEIRA else OwnerType.SOLO
                    shieldChange = gameProperties.transferShield - quadra.shield
                    ownerChanged = true
                } else if (quadra.isInCooldown() && projectedShield < gameProperties.transferShield) {
                    // Cap at transfer shield during cooldown
                    shieldChange = gameProperties.transferShield - quadra.shield
                }
            }
            
            TerritoryActionType.DEFENSE -> {
                shieldChange = minOf(
                    gameProperties.defenseHeal,
                    gameProperties.maxShield - quadra.shield
                )
                quadra.lastDefenseAt = Instant.now()
            }
        }
        
        val shieldAfter = (quadra.shield + shieldChange).coerceIn(0, gameProperties.maxShield)
        
        // Update quadra
        quadra.shield = shieldAfter
        if (ownerChanged) {
            quadra.ownerId = newOwnerId
            quadra.ownerType = newOwnerType
            quadra.cooldownUntil = Instant.now().plus(gameProperties.cooldownHours, ChronoUnit.HOURS)
            quadra.guardian = user
            quadra.guardianContribution = 1
            
            // Update stats
            updateOwnershipStats(previousOwnerId, previousOwnerType, newOwnerId, newOwnerType)
        }
        quadra.lastActionAt = Instant.now()
        quadraRepository.save(quadra)
        
        // Record action
        val action = TerritoryAction(
            user = user,
            bandeira = bandeira,
            quadra = quadra,
            actionType = actionType,
            shieldChange = shieldChange,
            shieldBefore = shieldBefore,
            shieldAfter = shieldAfter,
            ownerChanged = ownerChanged
        )
        territoryActionRepository.save(action)
        
        // Update guardian if not owner change
        if (!ownerChanged && actionType != TerritoryActionType.CONQUEST) {
            updateGuardian(quadra, user)
        }
        
        // Send notifications
        val inDispute = shieldAfter < gameProperties.disputeThreshold && quadra.ownerType != null
        if (ownerChanged) {
            notificationService.notifyQuadraTakeover(quadra)
        } else if (inDispute && shieldBefore >= gameProperties.disputeThreshold) {
            notificationService.notifyQuadraInDispute(quadra)
        }
        
        // Update user stats
        if (actionType == TerritoryActionType.CONQUEST || ownerChanged) {
            user.totalQuadrasConquered++
            userRepository.save(user)
        }
        
        return ActionResult(
            success = true,
            actionType = actionType,
            ownerChanged = ownerChanged,
            previousOwnerId = previousOwnerId,
            previousOwnerType = previousOwnerType,
            newOwnerId = newOwnerId,
            newOwnerType = newOwnerType,
            shieldChange = shieldChange,
            shieldBefore = shieldBefore,
            shieldAfter = shieldAfter,
            inDispute = inDispute,
            quadraId = quadraId,
            cooldownUntil = quadra.cooldownUntil
        )
    }
    
    /**
     * Validate if an action is allowed
     */
    private fun validateAction(quadra: Quadra, user: User, actionType: TerritoryActionType): String? {
        return when (actionType) {
            TerritoryActionType.CONQUEST -> {
                if (!quadra.isNeutral()) "quadra_already_owned"
                else null
            }
            TerritoryActionType.ATTACK -> {
                when {
                    quadra.isNeutral() -> "cannot_attack_neutral"
                    isOwner(quadra, user) -> "cannot_attack_own_quadra"
                    quadra.isInCooldown() && quadra.shield <= gameProperties.transferShield -> "quadra_in_cooldown"
                    else -> null
                }
            }
            TerritoryActionType.DEFENSE -> {
                if (!isOwner(quadra, user)) "cannot_defend_rival_quadra"
                else null
            }
        }
    }
    
    /**
     * Check if user (or their bandeira) owns the quadra
     */
    private fun isOwner(quadra: Quadra, user: User): Boolean {
        return when (quadra.ownerType) {
            OwnerType.SOLO -> quadra.ownerId == user.id
            OwnerType.BANDEIRA -> quadra.ownerId == user.bandeira?.id
            null -> false
        }
    }
    
    /**
     * Create a new quadra at the given H3 index
     */
    private fun createQuadra(quadraId: String): Quadra {
        val center = h3GridService.getTileCenterAsPoint(quadraId)
        val quadra = Quadra(id = quadraId, center = center)
        return quadraRepository.save(quadra)
    }
    
    /**
     * Update the guardian (highest weekly contributor) for a quadra
     */
    private fun updateGuardian(quadra: Quadra, user: User) {
        val weekStart = Instant.now().minus(7, ChronoUnit.DAYS)
        val contributions = territoryActionRepository.findWeeklyContributorsByQuadra(quadra.id, weekStart)
        
        if (contributions.isNotEmpty()) {
            val topContributor = contributions.first()
            val userId = topContributor[0] as UUID
            val contribution = (topContributor[1] as Number).toInt()
            
            if (quadra.guardian?.id != userId || quadra.guardianContribution != contribution) {
                quadra.guardian = userRepository.findById(userId).orElse(null)
                quadra.guardianContribution = contribution
                quadraRepository.save(quadra)
            }
        }
    }
    
    /**
     * Update ownership statistics when a tile changes hands
     */
    private fun updateOwnershipStats(
        previousOwnerId: UUID?,
        previousOwnerType: OwnerType?,
        newOwnerId: UUID?,
        newOwnerType: OwnerType?
    ) {
        // Decrement previous owner's count
        if (previousOwnerId != null) {
            when (previousOwnerType) {
                OwnerType.SOLO -> {
                    userRepository.findById(previousOwnerId).ifPresent { user ->
                        user.totalQuadrasConquered = maxOf(0, user.totalQuadrasConquered - 1)
                        userRepository.save(user)
                    }
                }
                OwnerType.BANDEIRA -> {
                    bandeiraRepository.findById(previousOwnerId).ifPresent { bandeira ->
                        bandeira.totalQuadras = maxOf(0, bandeira.totalQuadras - 1)
                        bandeiraRepository.save(bandeira)
                    }
                }
                null -> {}
            }
        }
        
        // Increment new owner's count
        if (newOwnerId != null) {
            when (newOwnerType) {
                OwnerType.BANDEIRA -> {
                    bandeiraRepository.findById(newOwnerId).ifPresent { bandeira ->
                        bandeira.totalQuadras++
                        bandeiraRepository.save(bandeira)
                    }
                }
                else -> {} // Solo stats updated separately
            }
        }
    }
    
    /**
     * Apply decay to quadras that haven't been defended recently
     */
    @Transactional
    fun applyDecay() {
        val decayThreshold = Instant.now().minus(gameProperties.decayStartDays.toLong(), ChronoUnit.DAYS)
        val quadras = quadraRepository.findQuadrasForDecay(decayThreshold)
        
        quadras.forEach { quadra ->
            if (quadra.shield > gameProperties.decayMinimum) {
                val newShield = maxOf(gameProperties.decayMinimum, quadra.shield - gameProperties.decayPerDay)
                quadra.shield = newShield
                quadraRepository.save(quadra)
                
                // Notify if entering dispute
                if (newShield < gameProperties.disputeThreshold) {
                    notificationService.notifyQuadraInDispute(quadra)
                }
            }
        }
    }
}
