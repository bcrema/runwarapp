package com.runwar.domain.territory

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.Instant
import java.util.*

@Repository
interface TerritoryActionRepository : JpaRepository<TerritoryAction, UUID> {
    
    fun findByTileIdOrderByCreatedAtDesc(tileId: String): List<TerritoryAction>
    
    fun findByUserIdOrderByCreatedAtDesc(userId: UUID): List<TerritoryAction>
    
    @Query("""
        SELECT ta FROM TerritoryAction ta 
        WHERE ta.tile.id = :tileId 
        AND ta.createdAt >= :since 
        ORDER BY ta.createdAt DESC
    """)
    fun findByTileIdSince(tileId: String, since: Instant): List<TerritoryAction>
    
    @Query("""
        SELECT ta.user.id, SUM(
            CASE WHEN ta.actionType = 'ATTACK' THEN 1 ELSE 0 END + 
            CASE WHEN ta.actionType = 'DEFENSE' THEN 1 ELSE 0 END
        ) as contribution
        FROM TerritoryAction ta 
        WHERE ta.tile.id = :tileId 
        AND ta.createdAt >= :weekStart 
        GROUP BY ta.user.id 
        ORDER BY contribution DESC
    """)
    fun findWeeklyContributorsByTile(tileId: String, weekStart: Instant): List<Array<Any>>
    
    @Query("""
        SELECT COUNT(ta) FROM TerritoryAction ta 
        WHERE ta.user.id = :userId 
        AND ta.createdAt >= :since
    """)
    fun countUserActionsToday(userId: UUID, since: Instant): Int
    
    @Query("""
        SELECT COUNT(ta) FROM TerritoryAction ta 
        WHERE ta.bandeira.id = :bandeiraId 
        AND ta.createdAt >= :since
    """)
    fun countBandeiraActionsToday(bandeiraId: UUID, since: Instant): Int
}
