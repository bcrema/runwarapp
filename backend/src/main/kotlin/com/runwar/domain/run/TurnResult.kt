package com.runwar.domain.run

import com.runwar.domain.quadra.OwnerType
import java.time.Instant
import java.util.UUID

data class TurnResult(
    val actionType: TerritoryActionType?,
    val quadraId: String?,
    val h3Index: String?,
    val previousOwner: OwnerSnapshot?,
    val newOwner: OwnerSnapshot?,
    val shieldBefore: Int?,
    val shieldAfter: Int?,
    val cooldownUntil: Instant?,
    val disputeState: DisputeState?,
    val capsRemaining: CapsRemaining,
    val reasons: List<String>
)

data class OwnerSnapshot(
    val id: UUID?,
    val type: OwnerType?
)

data class CapsRemaining(
    val userActionsRemaining: Int,
    val bandeiraActionsRemaining: Int?
)

enum class DisputeState {
    NONE,
    STABLE,
    DISPUTED
}
