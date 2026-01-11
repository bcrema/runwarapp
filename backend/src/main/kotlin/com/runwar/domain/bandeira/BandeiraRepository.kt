package com.runwar.domain.bandeira

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface BandeiraRepository : JpaRepository<Bandeira, UUID> {
    fun findBySlug(slug: String): Bandeira?
    fun existsBySlug(slug: String): Boolean
    
    @Query("SELECT b FROM Bandeira b ORDER BY b.totalTiles DESC")
    fun findAllOrderByTotalTilesDesc(): List<Bandeira>
    
    @Query("SELECT b FROM Bandeira b WHERE b.category = :category ORDER BY b.totalTiles DESC")
    fun findByCategory(category: BandeiraCategory): List<Bandeira>
    
    fun findByNameContainingIgnoreCase(name: String): List<Bandeira>
}
