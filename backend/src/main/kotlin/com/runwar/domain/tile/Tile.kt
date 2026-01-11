package com.runwar.domain.tile

import com.runwar.domain.user.User
import jakarta.persistence.*
import org.locationtech.jts.geom.Point
import java.time.Instant

@Entity
@Table(name = "tiles")
class Tile(
    @Id
    val id: String, // H3 index
    
    @Column(columnDefinition = "geometry(Point, 4326)")
    val center: Point,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "owner_type")
    var ownerType: OwnerType? = null,
    
    @Column(name = "owner_id")
    var ownerId: java.util.UUID? = null,
    
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
    fun isInCooldown(): Boolean {
        return cooldownUntil?.let { Instant.now().isBefore(it) } ?: false
    }
    
    fun isInDispute(threshold: Int): Boolean {
        return ownerType != null && shield < threshold
    }
    
    fun isNeutral(): Boolean = ownerType == null
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Tile) return false
        return id == other.id
    }
    
    override fun hashCode(): Int = id.hashCode()
}

enum class OwnerType {
    SOLO,
    BANDEIRA
}
