package com.runwar.domain.tile

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.time.Instant
import java.util.*

@Repository
interface TileRepository : JpaRepository<Tile, String> {
    
    @Query("""
        SELECT t FROM Tile t 
        WHERE t.ownerId = :ownerId AND t.ownerType = :ownerType
    """)
    fun findByOwner(ownerId: UUID, ownerType: OwnerType): List<Tile>
    
    fun findByOwnerId(ownerId: UUID): List<Tile>
    
    @Query("SELECT COUNT(t) FROM Tile t WHERE t.ownerId = :ownerId")
    fun countByOwnerId(ownerId: UUID): Int
    
    @Query("""
        SELECT t FROM Tile t 
        WHERE t.ownerType IS NOT NULL 
        AND t.shield < :threshold
    """)
    fun findTilesInDispute(threshold: Int): List<Tile>
    
    @Query("""
        SELECT t FROM Tile t 
        WHERE t.ownerType IS NOT NULL 
        AND t.lastDefenseAt IS NOT NULL 
        AND t.lastDefenseAt < :threshold
    """)
    fun findTilesForDecay(threshold: Instant): List<Tile>
    
    @Modifying
    @Query("""
        UPDATE Tile t 
        SET t.shield = GREATEST(:minimum, t.shield - :decayAmount) 
        WHERE t.id IN :tileIds
    """)
    fun applyDecay(tileIds: List<String>, decayAmount: Int, minimum: Int)
    
    @Query(value = """
        SELECT t.* FROM tiles t 
        WHERE ST_DWithin(
            t.center::geography, 
            ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, 
            :radiusMeters
        )
    """, nativeQuery = true)
    fun findTilesWithinRadius(lat: Double, lng: Double, radiusMeters: Double): List<Tile>
    
    @Query(value = """
        SELECT t.* FROM tiles t 
        WHERE t.center && ST_MakeEnvelope(:minLng, :minLat, :maxLng, :maxLat, 4326)
    """, nativeQuery = true)
    fun findTilesInBoundingBox(minLat: Double, minLng: Double, maxLat: Double, maxLng: Double): List<Tile>
}
