package com.runwar.game

import com.runwar.config.GameProperties
import com.runwar.domain.bandeira.BandeiraRepository
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.territory.TerritoryAction
import com.runwar.domain.territory.TerritoryActionRepository
import com.runwar.domain.tile.OwnerType
import com.runwar.domain.tile.Tile
import com.runwar.domain.tile.TileRepository
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
    private val tileRepository: TileRepository,
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
        val tileId: String? = null,
        val cooldownUntil: Instant? = null
    ) {
        companion object {
            fun failure(reason: String) = ActionResult(success = false, reason = reason)

            fun failureWithTile(reason: String, tile: Tile, disputeThreshold: Int) =
                ActionResult(
                    success = false,
                    reason = reason,
                    previousOwnerId = tile.ownerId,
                    previousOwnerType = tile.ownerType,
                    newOwnerId = tile.ownerId,
                    newOwnerType = tile.ownerType,
                    shieldBefore = tile.shield,
                    shieldAfter = tile.shield,
                    inDispute = tile.isInDispute(disputeThreshold),
                    tileId = tile.id,
                    cooldownUntil = tile.cooldownUntil
                )
        }
    }
    
    /**
     * Determine the appropriate action type for a user on a tile
     */
    fun determineActionType(tile: Tile, user: User): TerritoryActionType? {
        return when {
            tile.isNeutral() -> TerritoryActionType.CONQUEST
            isOwner(tile, user) -> TerritoryActionType.DEFENSE
            else -> TerritoryActionType.ATTACK
        }
    }
    
    /**
     * Process a territory action (conquest, attack, or defense)
     */
    @Transactional
    fun processAction(
        tileId: String,
        user: User,
        providedActionType: TerritoryActionType? = null
    ): ActionResult {
        // Find or create tile
        val tile = tileRepository.findById(tileId).orElseGet {
            createTile(tileId)
        }
        
        // Determine action type if not provided
        val actionType = providedActionType ?: determineActionType(tile, user)
            ?: return ActionResult.failureWithTile(
                "cannot_determine_action",
                tile,
                gameProperties.disputeThreshold
            )
        
        // Validate action is allowed
        val validationError = validateAction(tile, user, actionType)
        if (validationError != null) {
            return ActionResult.failureWithTile(
                validationError,
                tile,
                gameProperties.disputeThreshold
            )
        }
        
        val bandeira = user.bandeira
        val shieldBefore = tile.shield
        var shieldChange = 0
        var ownerChanged = false
        val previousOwnerId = tile.ownerId
        val previousOwnerType = tile.ownerType
        var newOwnerId = tile.ownerId
        var newOwnerType = tile.ownerType
        
        when (actionType) {
            TerritoryActionType.CONQUEST -> {
                shieldChange = gameProperties.conquestInitialShield
                newOwnerId = bandeira?.id ?: user.id
                newOwnerType = if (bandeira != null) OwnerType.BANDEIRA else OwnerType.SOLO
                ownerChanged = true
            }
            
            TerritoryActionType.ATTACK -> {
                shieldChange = -gameProperties.attackDamage
                val projectedShield = tile.shield + shieldChange
                
                if (projectedShield <= 0 && !tile.isInCooldown()) {
                    // Transfer ownership
                    newOwnerId = bandeira?.id ?: user.id
                    newOwnerType = if (bandeira != null) OwnerType.BANDEIRA else OwnerType.SOLO
                    shieldChange = gameProperties.transferShield - tile.shield
                    ownerChanged = true
                } else if (tile.isInCooldown() && projectedShield < gameProperties.transferShield) {
                    // Cap at transfer shield during cooldown
                    shieldChange = gameProperties.transferShield - tile.shield
                }
            }
            
            TerritoryActionType.DEFENSE -> {
                shieldChange = minOf(
                    gameProperties.defenseHeal,
                    gameProperties.maxShield - tile.shield
                )
                tile.lastDefenseAt = Instant.now()
            }
        }
        
        val shieldAfter = (tile.shield + shieldChange).coerceIn(0, gameProperties.maxShield)
        
        // Update tile
        tile.shield = shieldAfter
        if (ownerChanged) {
            tile.ownerId = newOwnerId
            tile.ownerType = newOwnerType
            tile.cooldownUntil = Instant.now().plus(gameProperties.cooldownHours, ChronoUnit.HOURS)
            tile.guardian = user
            tile.guardianContribution = 1
            
            // Update stats
            updateOwnershipStats(previousOwnerId, previousOwnerType, newOwnerId, newOwnerType)
        }
        tile.lastActionAt = Instant.now()
        tileRepository.save(tile)
        
        // Record action
        val action = TerritoryAction(
            user = user,
            bandeira = bandeira,
            tile = tile,
            actionType = actionType,
            shieldChange = shieldChange,
            shieldBefore = shieldBefore,
            shieldAfter = shieldAfter,
            ownerChanged = ownerChanged
        )
        territoryActionRepository.save(action)
        
        // Update guardian if not owner change
        if (!ownerChanged && actionType != TerritoryActionType.CONQUEST) {
            updateGuardian(tile, user)
        }
        
        // Send notifications
        val inDispute = shieldAfter < gameProperties.disputeThreshold && tile.ownerType != null
        if (ownerChanged) {
            notificationService.notifyTileTakeover(tile)
        } else if (inDispute && shieldBefore >= gameProperties.disputeThreshold) {
            notificationService.notifyTileInDispute(tile)
        }
        
        // Update user stats
        if (actionType == TerritoryActionType.CONQUEST || ownerChanged) {
            user.totalTilesConquered++
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
            tileId = tileId,
            cooldownUntil = tile.cooldownUntil
        )
    }
    
    /**
     * Validate if an action is allowed
     */
    private fun validateAction(tile: Tile, user: User, actionType: TerritoryActionType): String? {
        return when (actionType) {
            TerritoryActionType.CONQUEST -> {
                if (!tile.isNeutral()) "tile_already_owned"
                else null
            }
            TerritoryActionType.ATTACK -> {
                when {
                    tile.isNeutral() -> "cannot_attack_neutral"
                    isOwner(tile, user) -> "cannot_attack_own_tile"
                    tile.isInCooldown() && tile.shield <= gameProperties.transferShield -> "tile_in_cooldown"
                    else -> null
                }
            }
            TerritoryActionType.DEFENSE -> {
                if (!isOwner(tile, user)) "cannot_defend_rival_tile"
                else null
            }
        }
    }
    
    /**
     * Check if user (or their bandeira) owns the tile
     */
    private fun isOwner(tile: Tile, user: User): Boolean {
        return when (tile.ownerType) {
            OwnerType.SOLO -> tile.ownerId == user.id
            OwnerType.BANDEIRA -> tile.ownerId == user.bandeira?.id
            null -> false
        }
    }
    
    /**
     * Create a new tile at the given H3 index
     */
    private fun createTile(tileId: String): Tile {
        val center = h3GridService.getTileCenterAsPoint(tileId)
        val tile = Tile(id = tileId, center = center)
        return tileRepository.save(tile)
    }
    
    /**
     * Update the guardian (highest weekly contributor) for a tile
     */
    private fun updateGuardian(tile: Tile, user: User) {
        val weekStart = Instant.now().minus(7, ChronoUnit.DAYS)
        val contributions = territoryActionRepository.findWeeklyContributorsByTile(tile.id, weekStart)
        
        if (contributions.isNotEmpty()) {
            val topContributor = contributions.first()
            val userId = topContributor[0] as UUID
            val contribution = (topContributor[1] as Number).toInt()
            
            if (tile.guardian?.id != userId || tile.guardianContribution != contribution) {
                tile.guardian = userRepository.findById(userId).orElse(null)
                tile.guardianContribution = contribution
                tileRepository.save(tile)
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
                        user.totalTilesConquered = maxOf(0, user.totalTilesConquered - 1)
                        userRepository.save(user)
                    }
                }
                OwnerType.BANDEIRA -> {
                    bandeiraRepository.findById(previousOwnerId).ifPresent { bandeira ->
                        bandeira.totalTiles = maxOf(0, bandeira.totalTiles - 1)
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
                        bandeira.totalTiles++
                        bandeiraRepository.save(bandeira)
                    }
                }
                else -> {} // Solo stats updated separately
            }
        }
    }
    
    /**
     * Apply decay to tiles that haven't been defended recently
     */
    @Transactional
    fun applyDecay() {
        val decayThreshold = Instant.now().minus(gameProperties.decayStartDays.toLong(), ChronoUnit.DAYS)
        val tiles = tileRepository.findTilesForDecay(decayThreshold)
        
        tiles.forEach { tile ->
            if (tile.shield > gameProperties.decayMinimum) {
                val newShield = maxOf(gameProperties.decayMinimum, tile.shield - gameProperties.decayPerDay)
                tile.shield = newShield
                tileRepository.save(tile)
                
                // Notify if entering dispute
                if (newShield < gameProperties.disputeThreshold) {
                    notificationService.notifyTileInDispute(tile)
                }
            }
        }
    }
}
