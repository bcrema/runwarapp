package com.runwar.game

import com.runwar.domain.run.Run
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.territory.TerritoryAction
import com.runwar.domain.territory.TerritoryActionRepository
import com.runwar.domain.tile.OwnerType
import com.runwar.domain.tile.Tile
import com.runwar.domain.tile.TileRepository
import com.runwar.domain.user.User
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.temporal.ChronoUnit

@Service
class TerritoryEngine(
    private val tileRepository: TileRepository,
    private val territoryActionRepository: TerritoryActionRepository
) {
    data class ActionOutcome(
        val actionType: TerritoryActionType,
        val ownerChanged: Boolean,
        val shieldBefore: Int,
        val shieldAfter: Int,
        val inDispute: Boolean,
        val cooldownUntil: Instant?
    )

    @Transactional
    fun applyAction(run: Run, tile: Tile, actor: User): ActionOutcome {
        val actionType = determineActionType(tile, actor)
        val shieldBefore = tile.shield
        var shieldAfter = tile.shield
        var ownerChanged = false

        when (actionType) {
            TerritoryActionType.CONQUEST -> {
                val (ownerId, ownerType) = resolveOwner(actor)
                tile.ownerId = ownerId
                tile.ownerType = ownerType
                shieldAfter = CONQUEST_SHIELD
                tile.cooldownUntil = null
                ownerChanged = true
            }
            TerritoryActionType.ATTACK -> {
                val projectedShield = tile.shield - ATTACK_DAMAGE
                val inCooldown = tile.isInCooldown()
                if (!inCooldown && projectedShield <= 0) {
                    val (ownerId, ownerType) = resolveOwner(actor)
                    tile.ownerId = ownerId
                    tile.ownerType = ownerType
                    shieldAfter = TRANSFER_SHIELD
                    tile.cooldownUntil = Instant.now().plus(COOLDOWN_HOURS, ChronoUnit.HOURS)
                    ownerChanged = true
                } else if (inCooldown && projectedShield <= 0) {
                    // While in cooldown, prevent ownership transfer and cap shield at the transfer threshold
                    shieldAfter = 1
                } else {
                    shieldAfter = projectedShield
                }
            }
            TerritoryActionType.DEFENSE -> {
                shieldAfter = minOf(MAX_SHIELD, tile.shield + DEFENSE_BOOST)
            }
        }

        shieldAfter = shieldAfter.coerceIn(0, MAX_SHIELD)
        tile.shield = shieldAfter
        tileRepository.save(tile)

        val action = TerritoryAction(
            run = run,
            user = actor,
            bandeira = actor.bandeira,
            tile = tile,
            actionType = actionType,
            shieldChange = shieldAfter - shieldBefore,
            shieldBefore = shieldBefore,
            shieldAfter = shieldAfter,
            ownerChanged = ownerChanged
        )
        territoryActionRepository.save(action)

        return ActionOutcome(
            actionType = actionType,
            ownerChanged = ownerChanged,
            shieldBefore = shieldBefore,
            shieldAfter = shieldAfter,
            inDispute = tile.isInDispute(DISPUTE_THRESHOLD),
            cooldownUntil = tile.cooldownUntil
        )
    }

    private fun determineActionType(tile: Tile, actor: User): TerritoryActionType {
        return when {
            tile.isNeutral() -> TerritoryActionType.CONQUEST
            isOwner(tile, actor) -> TerritoryActionType.DEFENSE
            else -> TerritoryActionType.ATTACK
        }
    }

    private fun isOwner(tile: Tile, actor: User): Boolean {
        return when (tile.ownerType) {
            OwnerType.SOLO -> tile.ownerId == actor.id
            OwnerType.BANDEIRA -> tile.ownerId == actor.bandeira?.id
            null -> false
        }
    }

    private fun resolveOwner(actor: User): Pair<java.util.UUID, OwnerType> {
        val bandeira = actor.bandeira
        return if (bandeira != null) {
            bandeira.id to OwnerType.BANDEIRA
        } else {
            actor.id to OwnerType.SOLO
        }
    }

    companion object {
        const val DEFENSE_BOOST = 20
        const val ATTACK_DAMAGE = 35
        const val CONQUEST_SHIELD = 100
        const val TRANSFER_SHIELD = 65
        const val MAX_SHIELD = 100
        const val DISPUTE_THRESHOLD = 70
        const val COOLDOWN_HOURS = 18L
    }
}
