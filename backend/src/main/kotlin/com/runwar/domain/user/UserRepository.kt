package com.runwar.domain.user

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UserRepository : JpaRepository<User, UUID> {
    fun findByEmail(email: String): User?
    fun findByUsername(username: String): User?
    fun existsByEmail(email: String): Boolean
    fun existsByUsername(username: String): Boolean
    
    @Query("SELECT u FROM User u WHERE u.bandeira.id = :bandeiraId")
    fun findByBandeiraId(bandeiraId: UUID): List<User>
    
    @Query("SELECT u FROM User u WHERE u.bandeira.id = :bandeiraId ORDER BY u.totalTilesConquered DESC")
    fun findTopContributorsByBandeira(bandeiraId: UUID): List<User>
    
    @Query("""
        SELECT u FROM User u 
        WHERE u.bandeira IS NULL 
        ORDER BY u.totalTilesConquered DESC
    """)
    fun findTopSoloPlayers(): List<User>
}
