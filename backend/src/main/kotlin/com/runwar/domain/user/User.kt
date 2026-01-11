package com.runwar.domain.user

import com.runwar.domain.bandeira.Bandeira
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.Instant
import java.util.*

@Entity
@Table(name = "users")
class User(
    @Id
    val id: UUID = UUID.randomUUID(),
    
    @Column(unique = true, nullable = false)
    val email: String,
    
    @Column(unique = true, nullable = false)
    var username: String,
    
    @Column(name = "password_hash", nullable = false)
    var passwordHash: String,
    
    @Column(name = "avatar_url")
    var avatarUrl: String? = null,
    
    @Column(name = "is_public")
    var isPublic: Boolean = true,
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bandeira_id")
    var bandeira: Bandeira? = null,
    
    @Enumerated(EnumType.STRING)
    var role: UserRole = UserRole.MEMBER,
    
    @Column(name = "total_runs")
    var totalRuns: Int = 0,
    
    @Column(name = "total_distance")
    var totalDistance: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "total_tiles_conquered")
    var totalTilesConquered: Int = 0,
    
    @Column(name = "created_at")
    val createdAt: Instant = Instant.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is User) return false
        return id == other.id
    }
    
    override fun hashCode(): Int = id.hashCode()
}

enum class UserRole {
    ADMIN,
    COACH,
    MEMBER
}
