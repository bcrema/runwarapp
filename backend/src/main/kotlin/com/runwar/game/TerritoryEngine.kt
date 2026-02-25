package com.runwar.game

import com.runwar.domain.run.Run
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.territory.TerritoryAction
import com.runwar.domain.territory.TerritoryActionRepository
import com.runwar.domain.quadra.OwnerType
import com.runwar.domain.quadra.Quadra
import com.runwar.domain.quadra.QuadraRepository
import com.runwar.domain.user.User
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.temporal.ChronoUnit

@Service
class TerritoryEngine(
    private val quadraRepository: QuadraRepository,
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
    fun applyAction(run: Run, quadra: Quadra, actor: User): ActionOutcome {
        val actionType = determineActionType(quadra, actor)
        val shieldBefore = quadra.shield
        var shieldAfter = quadra.shield
        var ownerChanged = false

        when (actionType) {
            TerritoryActionType.CONQUEST -> {
                val (ownerId, ownerType) = resolveOwner(actor)
                quadra.ownerId = ownerId
                quadra.ownerType = ownerType
                shieldAfter = CONQUEST_SHIELD
                quadra.cooldownUntil = null
                ownerChanged = true
            }
            TerritoryActionType.ATTACK -> {
                val projectedShield = quadra.shield - ATTACK_DAMAGE
                val inCooldown = quadra.isInCooldown()
                if (!inCooldown && projectedShield <= 0) {
                    val (ownerId, ownerType) = resolveOwner(actor)
                    quadra.ownerId = ownerId
                    quadra.ownerType = ownerType
                    shieldAfter = TRANSFER_SHIELD
                    quadra.cooldownUntil = Instant.now().plus(COOLDOWN_HOURS, ChronoUnit.HOURS)
                    ownerChanged = true
                } else if (inCooldown && projectedShield <= 0) {
                    // While in cooldown, prevent ownership transfer and cap shield at the transfer threshold
                    shieldAfter = 1
                } else {
                    shieldAfter = projectedShield
                }
            }
            TerritoryActionType.DEFENSE -> {
                shieldAfter = minOf(MAX_SHIELD, quadra.shield + DEFENSE_BOOST)
            }
        }

        // Update activity timestamps for decay and tracking consistency
        val now = Instant.now()
        quadra.lastActionAt = now
        if (actionType == TerritoryActionType.DEFENSE) {
            quadra.lastDefenseAt = now
        }
        shieldAfter = shieldAfter.coerceIn(0, MAX_SHIELD)
        quadra.shield = shieldAfter
        quadraRepository.save(quadra)

        val action = TerritoryAction(
            run = run,
            user = actor,
            bandeira = actor.bandeira,
            quadra = quadra,
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
            inDispute = quadra.isInDispute(DISPUTE_THRESHOLD),
            cooldownUntil = quadra.cooldownUntil
        )
    }

    private fun determineActionType(quadra: Quadra, actor: User): TerritoryActionType {
        return when {
            quadra.isNeutral() -> TerritoryActionType.CONQUEST
            isOwner(quadra, actor) -> TerritoryActionType.DEFENSE
            else -> TerritoryActionType.ATTACK
        }
    }

    private fun isOwner(quadra: Quadra, actor: User): Boolean {
        return when (quadra.ownerType) {
            OwnerType.SOLO -> quadra.ownerId == actor.id
            OwnerType.BANDEIRA -> quadra.ownerId == actor.bandeira?.id
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
