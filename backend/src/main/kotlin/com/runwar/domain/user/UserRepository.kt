package com.runwar.domain.user

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UserRepository : JpaRepository<User, UUID> {
    fun findByEmail(email: String): User?
    @EntityGraph(attributePaths = ["bandeira"])
    fun findWithBandeiraByEmail(email: String): User?
    fun findByUsername(username: String): User?
    fun existsByEmail(email: String): Boolean
    fun existsByUsername(username: String): Boolean

    @EntityGraph(attributePaths = ["bandeira"])
    @Query("SELECT u FROM User u WHERE u.id = :id")
    fun findByIdWithBandeira(id: UUID): User?
    
    @Query("SELECT u FROM User u WHERE u.bandeira.id = :bandeiraId")
    fun findByBandeiraId(bandeiraId: UUID): List<User>
    
    @Query("SELECT u FROM User u WHERE u.bandeira.id = :bandeiraId ORDER BY u.totalQuadrasConquered DESC")
    fun findTopContributorsByBandeira(bandeiraId: UUID): List<User>
    
    @Query("""
        SELECT u FROM User u 
        WHERE u.bandeira IS NULL 
        ORDER BY u.totalQuadrasConquered DESC
    """)
    fun findTopSoloPlayers(): List<User>
}
