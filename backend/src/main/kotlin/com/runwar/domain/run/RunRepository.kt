package com.runwar.domain.run

import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.Instant
import java.util.*

@Repository
interface RunRepository : JpaRepository<Run, UUID> {
    
    fun findByUserIdOrderByCreatedAtDesc(userId: UUID, pageable: Pageable): List<Run>
    
    fun findByUserIdOrderByCreatedAtDesc(userId: UUID): List<Run>
    
    @Query("""
        SELECT r FROM Run r 
        WHERE r.user.id = :userId 
        AND r.createdAt >= :since 
        ORDER BY r.createdAt DESC
    """)
    fun findByUserIdSince(userId: UUID, since: Instant): List<Run>
    
    @Query("""
        SELECT r FROM Run r 
        WHERE r.user.bandeira.id = :bandeiraId 
        AND r.createdAt >= :since 
        ORDER BY r.createdAt DESC
    """)
    fun findByBandeiraIdSince(bandeiraId: UUID, since: Instant): List<Run>
    
    @Query("""
        SELECT COUNT(r) FROM Run r 
        WHERE r.user.id = :userId 
        AND r.isValidForTerritory = true 
        AND r.createdAt >= :since
    """)
    fun countTerritoryActionsToday(userId: UUID, since: Instant): Int
    
    @Query("""
        SELECT COUNT(r) FROM Run r 
        WHERE r.user.bandeira.id = :bandeiraId 
        AND r.isValidForTerritory = true 
        AND r.createdAt >= :since
    """)
    fun countBandeiraTerritoryActionsToday(bandeiraId: UUID, since: Instant): Int
}
