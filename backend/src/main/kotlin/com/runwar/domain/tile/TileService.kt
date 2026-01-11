package com.runwar.domain.tile

import com.runwar.config.GameProperties
import com.runwar.domain.bandeira.Bandeira
import com.runwar.domain.bandeira.BandeiraRepository
import com.runwar.domain.user.User
import com.runwar.domain.user.UserRepository
import com.runwar.game.H3GridService
import org.springframework.stereotype.Service
import java.util.*

@Service
class TileService(
    private val tileRepository: TileRepository,
    private val userRepository: UserRepository,
    private val bandeiraRepository: BandeiraRepository,
    private val h3GridService: H3GridService,
    private val gameProperties: GameProperties
) {
    
    data class TileDto(
        val id: String,
        val lat: Double,
        val lng: Double,
        val boundary: List<List<Double>>, // [[lat, lng], ...]
        val ownerType: String?,
        val ownerId: UUID?,
        val ownerName: String?,
        val ownerColor: String?, // for bandeira
        val shield: Int,
        val isInCooldown: Boolean,
        val isInDispute: Boolean,
        val guardianId: UUID?,
        val guardianName: String?
    )
    
    /**
     * Get tiles within a bounding box for map display
     */
    fun getTilesInBounds(
        minLat: Double,
        minLng: Double,
        maxLat: Double,
        maxLng: Double
    ): List<TileDto> {
        val tiles = tileRepository.findTilesInBoundingBox(minLat, minLng, maxLat, maxLng)
        return tiles.map { toDto(it) }
    }
    
    /**
     * Get a single tile by ID with full details
     */
    fun getTileById(tileId: String): TileDto? {
        return tileRepository.findById(tileId).map { toDto(it) }.orElse(null)
    }
    
    /**
     * Get all tiles owned by a user (solo)
     */
    fun getTilesByUser(userId: UUID): List<TileDto> {
        return tileRepository.findByOwner(userId, OwnerType.SOLO).map { toDto(it) }
    }
    
    /**
     * Get all tiles owned by a bandeira
     */
    fun getTilesByBandeira(bandeiraId: UUID): List<TileDto> {
        return tileRepository.findByOwner(bandeiraId, OwnerType.BANDEIRA).map { toDto(it) }
    }
    
    /**
     * Get tiles currently in dispute
     */
    fun getTilesInDispute(): List<TileDto> {
        return tileRepository.findTilesInDispute(gameProperties.disputeThreshold).map { toDto(it) }
    }
    
    /**
     * Get info about a tile for a specific coordinate
     */
    fun getTileForCoordinate(lat: Double, lng: Double): TileDto {
        val tileId = h3GridService.getTileId(lat, lng)
        val tile = tileRepository.findById(tileId).orElse(null)
        
        return if (tile != null) {
            toDto(tile)
        } else {
            // Return info for unclaimed tile
            val center = h3GridService.getTileCenter(tileId)
            val boundary = h3GridService.getTileBoundary(tileId)
            
            TileDto(
                id = tileId,
                lat = center.lat,
                lng = center.lng,
                boundary = boundary.map { listOf(it.lat, it.lng) },
                ownerType = null,
                ownerId = null,
                ownerName = null,
                ownerColor = null,
                shield = 0,
                isInCooldown = false,
                isInDispute = false,
                guardianId = null,
                guardianName = null
            )
        }
    }
    
    /**
     * Get game statistics
     */
    fun getStats(): GameStats {
        val allTilesInCuritiba = h3GridService.getAllTilesInCuritiba()
        val ownedTiles = tileRepository.findAll()
        val tilesInDispute = ownedTiles.filter { it.isInDispute(gameProperties.disputeThreshold) }
        
        return GameStats(
            totalTiles = allTilesInCuritiba.size,
            ownedTiles = ownedTiles.size,
            neutralTiles = allTilesInCuritiba.size - ownedTiles.size,
            tilesInDispute = tilesInDispute.size,
            disputePercentage = if (ownedTiles.isNotEmpty()) {
                (tilesInDispute.size.toDouble() / ownedTiles.size * 100).toInt()
            } else 0
        )
    }
    
    data class GameStats(
        val totalTiles: Int,
        val ownedTiles: Int,
        val neutralTiles: Int,
        val tilesInDispute: Int,
        val disputePercentage: Int
    )
    
    private fun toDto(tile: Tile): TileDto {
        val center = h3GridService.getTileCenter(tile.id)
        val boundary = h3GridService.getTileBoundary(tile.id)
        
        var ownerName: String? = null
        var ownerColor: String? = null
        
        when (tile.ownerType) {
            OwnerType.SOLO -> {
                tile.ownerId?.let { id ->
                    userRepository.findById(id).ifPresent { user ->
                        ownerName = user.username
                    }
                }
            }
            OwnerType.BANDEIRA -> {
                tile.ownerId?.let { id ->
                    bandeiraRepository.findById(id).ifPresent { bandeira ->
                        ownerName = bandeira.name
                        ownerColor = bandeira.color
                    }
                }
            }
            null -> {}
        }
        
        return TileDto(
            id = tile.id,
            lat = center.lat,
            lng = center.lng,
            boundary = boundary.map { listOf(it.lat, it.lng) },
            ownerType = tile.ownerType?.name,
            ownerId = tile.ownerId,
            ownerName = ownerName,
            ownerColor = ownerColor,
            shield = tile.shield,
            isInCooldown = tile.isInCooldown(),
            isInDispute = tile.isInDispute(gameProperties.disputeThreshold),
            guardianId = tile.guardian?.id,
            guardianName = tile.guardian?.username
        )
    }
}
