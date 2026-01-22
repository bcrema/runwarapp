package com.runwar.domain.tile

import com.runwar.config.GameProperties
import com.runwar.domain.bandeira.BandeiraRepository
import com.runwar.domain.user.UserRepository
import com.runwar.game.H3GridService
import org.springframework.stereotype.Service
import java.time.Duration
import java.time.Instant
import java.util.*
import java.util.concurrent.ConcurrentHashMap

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

    data class ViewportTileDto(
        val h3Index: String,
        val ownerType: String?,
        val ownerId: UUID?,
        val shield: Int,
        val dispute: Boolean,
        val cooldownUntil: java.time.Instant?,
        val colorKey: String?
    )

    data class BoundingBox(
        val minLng: Double,
        val minLat: Double,
        val maxLng: Double,
        val maxLat: Double
    )

    private data class CachedViewportTiles(
        val createdAt: Instant,
        val tiles: List<ViewportTileDto>
    )

    private val viewportCache = ConcurrentHashMap<String, CachedViewportTiles>()
    private val viewportCacheTtl = Duration.ofSeconds(5)
    
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
     * Get tiles within a bounding box with lightweight fields for map viewport rendering.
     */
    fun getViewportTiles(bounds: BoundingBox): List<ViewportTileDto> {
        val cacheKey = buildCacheKey(bounds)
        return viewportCache.compute(cacheKey) { _, cached ->
            if (cached != null && !isCacheExpired(cached)) {
                cached
            } else {
                val tiles = tileRepository.findTilesInBoundingBox(
                    bounds.minLat,
                    bounds.minLng,
                    bounds.maxLat,
                    bounds.maxLng
                )

                val bandeiraColors = loadBandeiraColors(tiles)

                CachedViewportTiles(
                    createdAt = Instant.now(),
                    tiles = tiles.map { toViewportDto(it, bandeiraColors) }
                )
            }
        }!!.tiles
    }

    /**
     * Convert a center point + radius (meters) to a bounding box.
     */
    fun toBoundingBox(centerLat: Double, centerLng: Double, radiusMeters: Double): BoundingBox {
        val metersPerDegreeLat = 111_320.0
        val deltaLat = radiusMeters / metersPerDegreeLat
        val deltaLng = radiusMeters / (metersPerDegreeLat * kotlin.math.cos(Math.toRadians(centerLat)))

        return BoundingBox(
            minLng = centerLng - deltaLng,
            minLat = centerLat - deltaLat,
            maxLng = centerLng + deltaLng,
            maxLat = centerLat + deltaLat
        )
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

    private fun toViewportDto(tile: Tile, bandeiraColors: Map<UUID, String>): ViewportTileDto {
        return ViewportTileDto(
            h3Index = tile.id,
            ownerType = tile.ownerType?.name,
            ownerId = tile.ownerId,
            shield = tile.shield,
            dispute = tile.isInDispute(gameProperties.disputeThreshold),
            cooldownUntil = tile.cooldownUntil,
            colorKey = tile.ownerId?.let { bandeiraColors[it] }
        )
    }

    private fun buildCacheKey(bounds: BoundingBox): String {
        return "res:${h3GridService.resolution}-" +
            "bbox:${formatCoord(bounds.minLng)}," +
            "${formatCoord(bounds.minLat)}," +
            "${formatCoord(bounds.maxLng)}," +
            "${formatCoord(bounds.maxLat)}"
    }

    private fun formatCoord(value: Double): String = String.format(Locale.US, "%.6f", value)

    private fun isCacheExpired(cached: CachedViewportTiles): Boolean {
        return Duration.between(cached.createdAt, Instant.now()) > viewportCacheTtl
    }

    private fun loadBandeiraColors(tiles: List<Tile>): Map<UUID, String> {
        val bandeiraIds = tiles.asSequence()
            .filter { it.ownerType == OwnerType.BANDEIRA }
            .mapNotNull { it.ownerId }
            .distinct()
            .toList()

        if (bandeiraIds.isEmpty()) {
            return emptyMap()
        }

        return bandeiraRepository.findAllById(bandeiraIds)
            .associate { it.id to it.color }
    }
}
