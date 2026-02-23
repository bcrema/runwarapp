package com.runwar.domain.tile

import java.util.UUID
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.server.ResponseStatusException

@RestController
@RequestMapping("/api/quadras")
class QuadraController(private val tileService: TileService) {

    companion object {
        private const val MAX_RADIUS_METERS = 50_000.0
    }

    @GetMapping(params = ["minLat", "minLng", "maxLat", "maxLng"])
    fun getQuadras(
        @RequestParam minLat: Double,
        @RequestParam minLng: Double,
        @RequestParam maxLat: Double,
        @RequestParam maxLng: Double
    ): ResponseEntity<List<TileService.QuadraDto>> {
        val quadras = tileService.getTilesInBounds(minLat, minLng, maxLat, maxLng)
        return ResponseEntity.ok(quadras)
    }

    @GetMapping(params = ["bbox"])
    fun getViewportQuadras(@RequestParam bbox: String): ResponseEntity<List<TileService.ViewportQuadraDto>> {
        val bounds = parseBbox(bbox)
            ?: return ResponseEntity.badRequest().build()
        if (!isValidBounds(bounds)) {
            return ResponseEntity.badRequest().build()
        }
        return ResponseEntity.ok(tileService.getViewportTiles(bounds))
    }

    @GetMapping(params = ["centerLat", "centerLng", "radiusMeters"])
    fun getViewportQuadrasByCenter(
        @RequestParam centerLat: Double,
        @RequestParam centerLng: Double,
        @RequestParam radiusMeters: Double
    ): ResponseEntity<List<TileService.ViewportQuadraDto>> {
        if (!isValidLat(centerLat) || !isValidLng(centerLng)) {
            return ResponseEntity.badRequest().build()
        }
        if (radiusMeters <= 0 || radiusMeters > MAX_RADIUS_METERS) {
            return ResponseEntity.badRequest().build()
        }
        val bounds = tileService.toBoundingBox(centerLat, centerLng, radiusMeters)
        if (!isValidBounds(bounds)) {
            return ResponseEntity.badRequest().build()
        }
        return ResponseEntity.ok(tileService.getViewportTiles(bounds))
    }

    @GetMapping("/{id}")
    fun getQuadraById(@PathVariable id: String): ResponseEntity<TileService.QuadraDto> {
        val quadra = tileService.getTileById(id)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Quadra not found")
        return ResponseEntity.ok(quadra)
    }

    @GetMapping("/at")
    fun getQuadraAtCoordinate(
        @RequestParam lat: Double,
        @RequestParam lng: Double
    ): ResponseEntity<TileService.QuadraDto> {
        val quadra = tileService.getTileForCoordinate(lat, lng)
        return ResponseEntity.ok(quadra)
    }

    @GetMapping("/user/{userId}")
    fun getQuadrasByUser(@PathVariable userId: UUID): ResponseEntity<List<TileService.QuadraDto>> {
        return ResponseEntity.ok(tileService.getTilesByUser(userId))
    }

    @GetMapping("/bandeira/{bandeiraId}")
    fun getQuadrasByBandeira(@PathVariable bandeiraId: UUID): ResponseEntity<List<TileService.QuadraDto>> {
        return ResponseEntity.ok(tileService.getTilesByBandeira(bandeiraId))
    }

    @GetMapping("/disputed")
    fun getDisputedQuadras(): ResponseEntity<List<TileService.QuadraDto>> {
        return ResponseEntity.ok(tileService.getTilesInDispute())
    }

    @GetMapping("/stats")
    fun getStats(): ResponseEntity<TileService.QuadraStats> {
        return ResponseEntity.ok(tileService.getStats())
    }

    private fun parseBbox(raw: String): TileService.BoundingBox? {
        val parts = raw.split(',').map { it.trim() }
        if (parts.size != 4) return null
        val values = parts.mapNotNull { it.toDoubleOrNull() }
        if (values.size != 4) return null
        return TileService.BoundingBox(
            minLng = values[0],
            minLat = values[1],
            maxLng = values[2],
            maxLat = values[3]
        )
    }

    private fun isValidLat(lat: Double): Boolean = lat in -90.0..90.0

    private fun isValidLng(lng: Double): Boolean = lng in -180.0..180.0

    private fun isValidBounds(bounds: TileService.BoundingBox): Boolean {
        return isValidLat(bounds.minLat) &&
            isValidLat(bounds.maxLat) &&
            isValidLng(bounds.minLng) &&
            isValidLng(bounds.maxLng) &&
            bounds.minLat < bounds.maxLat &&
            bounds.minLng != bounds.maxLng
    }
}
