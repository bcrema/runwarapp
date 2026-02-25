package com.runwar.domain.quadra

import java.time.Instant
import java.util.UUID
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface QuadraRepository : JpaRepository<Quadra, String> {

    @Query(
        """
        SELECT q FROM Quadra q
        WHERE q.ownerId = :ownerId AND q.ownerType = :ownerType
    """
    )
    fun findByOwner(ownerId: UUID, ownerType: OwnerType): List<Quadra>

    fun findByOwnerId(ownerId: UUID): List<Quadra>

    @Query("SELECT COUNT(q) FROM Quadra q WHERE q.ownerId = :ownerId")
    fun countByOwnerId(ownerId: UUID): Int

    @Query(
        """
        SELECT q FROM Quadra q
        WHERE q.ownerType IS NOT NULL
        AND q.shield < :threshold
    """
    )
    fun findQuadrasInDispute(threshold: Int): List<Quadra>

    @Query(
        """
        SELECT q FROM Quadra q
        WHERE q.ownerType IS NOT NULL
        AND q.lastDefenseAt IS NOT NULL
        AND q.lastDefenseAt < :threshold
    """
    )
    fun findQuadrasForDecay(threshold: Instant): List<Quadra>

    @Modifying
    @Query(
        """
        UPDATE Quadra q
        SET q.shield = GREATEST(:minimum, q.shield - :decayAmount)
        WHERE q.id IN :quadraIds
    """
    )
    fun applyDecay(quadraIds: List<String>, decayAmount: Int, minimum: Int)

    @Query(
        value =
            """
        SELECT q.* FROM quadras q
        WHERE ST_DWithin(
            q.center::geography,
            ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
            :radiusMeters
        )
    """,
        nativeQuery = true
    )
    fun findQuadrasWithinRadius(lat: Double, lng: Double, radiusMeters: Double): List<Quadra>

    @Query(
        value =
            """
        SELECT q.* FROM quadras q
        WHERE q.center && ST_MakeEnvelope(:minLng, :minLat, :maxLng, :maxLat, 4326)
    """,
        nativeQuery = true
    )
    fun findQuadrasInBoundingBox(minLat: Double, minLng: Double, maxLat: Double, maxLng: Double): List<Quadra>
}
