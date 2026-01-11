package com.runwar.domain.bandeira

import com.runwar.domain.user.User
import jakarta.persistence.*
import java.time.Instant
import java.util.*

@Entity
@Table(name = "bandeiras")
class Bandeira(
    @Id
    val id: UUID = UUID.randomUUID(),
    
    @Column(nullable = false)
    var name: String,
    
    @Column(unique = true, nullable = false)
    val slug: String,
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val category: BandeiraCategory,
    
    @Column(nullable = false)
    var color: String, // hex color like #FF5733
    
    @Column(name = "logo_url")
    var logoUrl: String? = null,
    
    @Column(name = "description")
    var description: String? = null,
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: User,
    
    @Column(name = "daily_action_cap")
    var dailyActionCap: Int = 60,
    
    @Column(name = "member_count")
    var memberCount: Int = 1,
    
    @Column(name = "total_tiles")
    var totalTiles: Int = 0,
    
    @Column(name = "created_at")
    val createdAt: Instant = Instant.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Bandeira) return false
        return id == other.id
    }
    
    override fun hashCode(): Int = id.hashCode()
}

enum class BandeiraCategory {
    ASSESSORIA,
    ACADEMIA,
    BOX,
    GRUPO
}
