package com.runwar.domain.territory

import com.runwar.domain.bandeira.Bandeira
import com.runwar.domain.quadra.Quadra
import com.runwar.domain.run.Run
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.user.User
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "territory_actions")
class TerritoryAction(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "run_id")
    val run: Run? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bandeira_id")
    val bandeira: Bandeira? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quadra_id", nullable = false)
    val quadra: Quadra,

    @Enumerated(EnumType.STRING)
    @Column(name = "action_type", nullable = false)
    val actionType: TerritoryActionType,

    @Column(name = "shield_change", nullable = false)
    val shieldChange: Int,

    @Column(name = "shield_before", nullable = false)
    val shieldBefore: Int,

    @Column(name = "shield_after", nullable = false)
    val shieldAfter: Int,

    @Column(name = "owner_changed")
    val ownerChanged: Boolean = false,

    @Column(name = "created_at")
    val createdAt: Instant = Instant.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TerritoryAction) return false
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()
}
