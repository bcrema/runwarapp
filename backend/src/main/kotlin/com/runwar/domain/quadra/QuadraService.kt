package com.runwar.domain.quadra

import com.runwar.config.GameProperties
import com.runwar.domain.bandeira.BandeiraRepository
import com.runwar.domain.user.UserRepository
import com.runwar.game.H3GridService
import java.time.Duration
import java.time.Instant
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class QuadraService(
    private val quadraRepository: QuadraRepository,
    private val userRepository: UserRepository,
    private val bandeiraRepository: BandeiraRepository,
    private val h3GridService: H3GridService,
    private val gameProperties: GameProperties
) {

    data class QuadraDto(
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
        val championUserId: UUID?,
        val championBandeiraId: UUID?,
        val championName: String?,
        val guardianId: UUID?,
        val guardianName: String?
    )

    data class ViewportQuadraDto(
        val h3Index: String,
        val ownerType: String?,
        val ownerId: UUID?,
        val shield: Int,
        val dispute: Boolean,
        val cooldownUntil: Instant?,
        val colorKey: String?
    )

    data class BoundingBox(
        val minLng: Double,
        val minLat: Double,
        val maxLng: Double,
        val maxLat: Double
    )

    private data class CachedViewportQuadras(
        val createdAt: Instant,
        val quadras: List<ViewportQuadraDto>
    )

    private val viewportCache = ConcurrentHashMap<String, CachedViewportQuadras>()
    private val viewportCacheTtl = Duration.ofSeconds(5)

    fun getQuadrasInBounds(
        minLat: Double,
        minLng: Double,
        maxLat: Double,
        maxLng: Double
    ): List<QuadraDto> {
        val quadras = quadraRepository.findQuadrasInBoundingBox(minLat, minLng, maxLat, maxLng)
        return quadras.map { toDto(it) }
    }

    fun getViewportQuadras(bounds: BoundingBox): List<ViewportQuadraDto> {
        val cacheKey = buildCacheKey(bounds)
        return viewportCache.compute(cacheKey) { _, cached ->
            if (cached != null && !isCacheExpired(cached)) {
                cached
            } else {
                val quadras =
                    quadraRepository.findQuadrasInBoundingBox(
                        bounds.minLat,
                        bounds.minLng,
                        bounds.maxLat,
                        bounds.maxLng
                    )

                val bandeiraColors = loadBandeiraColors(quadras)

                CachedViewportQuadras(
                    createdAt = Instant.now(),
                    quadras = quadras.map { toViewportDto(it, bandeiraColors) }
                )
            }
        }!!.quadras
    }

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

    fun getQuadraById(quadraId: String): QuadraDto? {
        return quadraRepository.findById(quadraId).map { toDto(it) }.orElse(null)
    }

    fun getQuadrasByUser(userId: UUID): List<QuadraDto> {
        return quadraRepository.findByOwner(userId, OwnerType.SOLO).map { toDto(it) }
    }

    fun getQuadrasByBandeira(bandeiraId: UUID): List<QuadraDto> {
        return quadraRepository.findByOwner(bandeiraId, OwnerType.BANDEIRA).map { toDto(it) }
    }

    fun getQuadrasInDispute(): List<QuadraDto> {
        return quadraRepository.findQuadrasInDispute(gameProperties.disputeThreshold).map { toDto(it) }
    }

    fun getQuadraForCoordinate(lat: Double, lng: Double): QuadraDto {
        val quadraId = h3GridService.getTileId(lat, lng)
        val quadra = quadraRepository.findById(quadraId).orElse(null)

        return if (quadra != null) {
            toDto(quadra)
        } else {
            val center = h3GridService.getTileCenter(quadraId)
            val boundary = h3GridService.getTileBoundary(quadraId)

            QuadraDto(
                id = quadraId,
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
                championUserId = null,
                championBandeiraId = null,
                championName = null,
                guardianId = null,
                guardianName = null
            )
        }
    }

    fun getStats(): QuadraStats {
        val allQuadrasInCuritiba = h3GridService.getAllTilesInCuritiba()
        val ownedQuadras = quadraRepository.findAll()
        val quadrasInDispute = ownedQuadras.filter { it.isInDispute(gameProperties.disputeThreshold) }

        return QuadraStats(
            totalQuadras = allQuadrasInCuritiba.size,
            ownedQuadras = ownedQuadras.size,
            neutralQuadras = allQuadrasInCuritiba.size - ownedQuadras.size,
            quadrasInDispute = quadrasInDispute.size,
            disputePercentage =
                if (ownedQuadras.isNotEmpty()) {
                    (quadrasInDispute.size.toDouble() / ownedQuadras.size * 100).toInt()
                } else {
                    0
                }
        )
    }

    data class QuadraStats(
        val totalQuadras: Int,
        val ownedQuadras: Int,
        val neutralQuadras: Int,
        val quadrasInDispute: Int,
        val disputePercentage: Int
    )

    private fun toDto(quadra: Quadra): QuadraDto {
        val center = h3GridService.getTileCenter(quadra.id)
        val boundary = h3GridService.getTileBoundary(quadra.id)

        var ownerName: String? = null
        var ownerColor: String? = null

        when (quadra.ownerType) {
            OwnerType.SOLO -> {
                quadra.ownerId?.let { id ->
                    userRepository.findById(id).ifPresent { user -> ownerName = user.username }
                }
            }
            OwnerType.BANDEIRA -> {
                quadra.ownerId?.let { id ->
                    bandeiraRepository.findById(id).ifPresent { bandeira ->
                        ownerName = bandeira.name
                        ownerColor = bandeira.color
                    }
                }
            }
            null -> {}
        }

        return QuadraDto(
            id = quadra.id,
            lat = center.lat,
            lng = center.lng,
            boundary = boundary.map { listOf(it.lat, it.lng) },
            ownerType = quadra.ownerType?.name,
            ownerId = quadra.ownerId,
            ownerName = ownerName,
            ownerColor = ownerColor,
            shield = quadra.shield,
            isInCooldown = quadra.isInCooldown(),
            isInDispute = quadra.isInDispute(gameProperties.disputeThreshold),
            championUserId = quadra.guardian?.id,
            championBandeiraId = quadra.guardian?.bandeira?.id,
            championName = quadra.guardian?.username,
            guardianId = quadra.guardian?.id,
            guardianName = quadra.guardian?.username
        )
    }

    private fun toViewportDto(quadra: Quadra, bandeiraColors: Map<UUID, String>): ViewportQuadraDto {
        return ViewportQuadraDto(
            h3Index = quadra.id,
            ownerType = quadra.ownerType?.name,
            ownerId = quadra.ownerId,
            shield = quadra.shield,
            dispute = quadra.isInDispute(gameProperties.disputeThreshold),
            cooldownUntil = quadra.cooldownUntil,
            colorKey = quadra.ownerId?.let { bandeiraColors[it] }
        )
    }

    private fun buildCacheKey(bounds: BoundingBox): String {
        return "res:${h3GridService.resolution}-" +
            "bbox:${formatCoord(bounds.minLng)}," +
            "${formatCoord(bounds.minLat)}," +
            "${formatCoord(bounds.maxLng)}," +
            "${formatCoord(bounds.maxLat)}-" +
            "dt:${gameProperties.disputeThreshold}"
    }

    private fun formatCoord(value: Double): String = String.format(Locale.US, "%.6f", value)

    private fun isCacheExpired(cached: CachedViewportQuadras): Boolean {
        return Duration.between(cached.createdAt, Instant.now()) > viewportCacheTtl
    }

    private fun loadBandeiraColors(quadras: List<Quadra>): Map<UUID, String> {
        val bandeiraIds =
            quadras
                .asSequence()
                .filter { it.ownerType == OwnerType.BANDEIRA }
                .mapNotNull { it.ownerId }
                .distinct()
                .toList()

        if (bandeiraIds.isEmpty()) {
            return emptyMap()
        }

        return bandeiraRepository.findAllById(bandeiraIds).associate { it.id to it.color }
    }
}
