package com.runwar.domain.quadra

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
class QuadraController(private val quadraService: QuadraService) {

    companion object {
        private const val MAX_RADIUS_METERS = 50_000.0
    }

    @GetMapping(params = ["minLat", "minLng", "maxLat", "maxLng"])
    fun getQuadras(
        @RequestParam minLat: Double,
        @RequestParam minLng: Double,
        @RequestParam maxLat: Double,
        @RequestParam maxLng: Double
    ): ResponseEntity<List<QuadraService.QuadraDto>> {
        val quadras = quadraService.getQuadrasInBounds(minLat, minLng, maxLat, maxLng)
        return ResponseEntity.ok(quadras)
    }

    @GetMapping(params = ["bbox"])
    fun getViewportQuadras(
        @RequestParam bbox: String
    ): ResponseEntity<List<QuadraService.ViewportQuadraDto>> {
        val bounds = parseBbox(bbox) ?: return ResponseEntity.badRequest().build()
        if (!isValidBounds(bounds)) {
            return ResponseEntity.badRequest().build()
        }
        return ResponseEntity.ok(quadraService.getViewportQuadras(bounds))
    }

    @GetMapping(params = ["centerLat", "centerLng", "radiusMeters"])
    fun getViewportQuadrasByCenter(
        @RequestParam centerLat: Double,
        @RequestParam centerLng: Double,
        @RequestParam radiusMeters: Double
    ): ResponseEntity<List<QuadraService.ViewportQuadraDto>> {
        if (!isValidLat(centerLat) || !isValidLng(centerLng)) {
            return ResponseEntity.badRequest().build()
        }
        if (radiusMeters <= 0 || radiusMeters > MAX_RADIUS_METERS) {
            return ResponseEntity.badRequest().build()
        }
        val bounds = quadraService.toBoundingBox(centerLat, centerLng, radiusMeters)
        if (!isValidBounds(bounds)) {
            return ResponseEntity.badRequest().build()
        }
        return ResponseEntity.ok(quadraService.getViewportQuadras(bounds))
    }

    @GetMapping("/{id}")
    fun getQuadraById(@PathVariable id: String): ResponseEntity<QuadraService.QuadraDto> {
        val quadra =
            quadraService.getQuadraById(id)
                ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Quadra not found")
        return ResponseEntity.ok(quadra)
    }

    @GetMapping("/at")
    fun getQuadraAtCoordinate(
        @RequestParam lat: Double,
        @RequestParam lng: Double
    ): ResponseEntity<QuadraService.QuadraDto> {
        val quadra = quadraService.getQuadraForCoordinate(lat, lng)
        return ResponseEntity.ok(quadra)
    }

    @GetMapping("/user/{userId}")
    fun getQuadrasByUser(@PathVariable userId: UUID): ResponseEntity<List<QuadraService.QuadraDto>> {
        return ResponseEntity.ok(quadraService.getQuadrasByUser(userId))
    }

    @GetMapping("/bandeira/{bandeiraId}")
    fun getQuadrasByBandeira(
        @PathVariable bandeiraId: UUID
    ): ResponseEntity<List<QuadraService.QuadraDto>> {
        return ResponseEntity.ok(quadraService.getQuadrasByBandeira(bandeiraId))
    }

    @GetMapping("/disputed")
    fun getDisputedQuadras(): ResponseEntity<List<QuadraService.QuadraDto>> {
        return ResponseEntity.ok(quadraService.getQuadrasInDispute())
    }

    @GetMapping("/stats")
    fun getStats(): ResponseEntity<QuadraService.QuadraStats> {
        return ResponseEntity.ok(quadraService.getStats())
    }

    private fun parseBbox(raw: String): QuadraService.BoundingBox? {
        val parts = raw.split(',').map { it.trim() }
        if (parts.size != 4) return null
        val values = parts.mapNotNull { it.toDoubleOrNull() }
        if (values.size != 4) return null
        return QuadraService.BoundingBox(
            minLng = values[0],
            minLat = values[1],
            maxLng = values[2],
            maxLat = values[3]
        )
    }

    private fun isValidLat(lat: Double): Boolean = lat in -90.0..90.0

    private fun isValidLng(lng: Double): Boolean = lng in -180.0..180.0

    private fun isValidBounds(bounds: QuadraService.BoundingBox): Boolean {
        return isValidLat(bounds.minLat) &&
            isValidLat(bounds.maxLat) &&
            isValidLng(bounds.minLng) &&
            isValidLng(bounds.maxLng) &&
            bounds.minLat < bounds.maxLat &&
            bounds.minLng != bounds.maxLng
    }
}
