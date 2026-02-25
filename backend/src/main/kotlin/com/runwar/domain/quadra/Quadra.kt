package com.runwar.domain.quadra

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
import org.locationtech.jts.geom.Point

@Entity
@Table(name = "quadras")
class Quadra(
    @Id
    val id: String, // H3 index

    @Column(columnDefinition = "geometry(Point, 4326)")
    val center: Point,

    @Enumerated(EnumType.STRING)
    @Column(name = "owner_type")
    var ownerType: OwnerType? = null,

    @Column(name = "owner_id")
    var ownerId: UUID? = null,

    var shield: Int = 0, // 0-100

    @Column(name = "cooldown_until")
    var cooldownUntil: Instant? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "guardian_id")
    var guardian: User? = null,

    @Column(name = "guardian_contribution")
    var guardianContribution: Int = 0,

    @Column(name = "last_defense_at")
    var lastDefenseAt: Instant? = null,

    @Column(name = "last_action_at")
    var lastActionAt: Instant? = null,

    @Column(name = "created_at")
    val createdAt: Instant = Instant.now()
) {
    fun isInCooldown(): Boolean = cooldownUntil?.let { Instant.now().isBefore(it) } ?: false

    fun isInDispute(threshold: Int): Boolean = ownerType != null && shield < threshold

    fun isNeutral(): Boolean = ownerType == null

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Quadra) return false
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()
}

enum class OwnerType {
    SOLO,
    BANDEIRA
}
