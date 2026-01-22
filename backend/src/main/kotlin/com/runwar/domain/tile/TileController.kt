package com.runwar.domain.tile

import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

@RestController
@RequestMapping("/api/tiles")
class TileController(private val tileService: TileService) {
    
    /**
     * Get tiles within a bounding box (for map display)
     */
    @GetMapping(params = ["minLat", "minLng", "maxLat", "maxLng"])
    fun getTiles(
        @RequestParam minLat: Double,
        @RequestParam minLng: Double,
        @RequestParam maxLat: Double,
        @RequestParam maxLng: Double
    ): ResponseEntity<List<TileService.TileDto>> {
        val tiles = tileService.getTilesInBounds(minLat, minLng, maxLat, maxLng)
        return ResponseEntity.ok(tiles)
    }

    /**
     * Get tiles within a viewport bounding box (for map rendering)
     * bbox format: minLng,minLat,maxLng,maxLat
     */
    @GetMapping(params = ["bbox"])
    fun getViewportTiles(@RequestParam bbox: String): ResponseEntity<List<TileService.ViewportTileDto>> {
        val bounds = parseBbox(bbox)
            ?: return ResponseEntity.badRequest().build()
        return ResponseEntity.ok(tileService.getViewportTiles(bounds))
    }

    /**
     * Get tiles within a viewport defined by a center and radius (meters)
     */
    @GetMapping(params = ["centerLat", "centerLng", "radiusMeters"])
    fun getViewportTilesByCenter(
        @RequestParam centerLat: Double,
        @RequestParam centerLng: Double,
        @RequestParam radiusMeters: Double
    ): ResponseEntity<List<TileService.ViewportTileDto>> {
        val bounds = tileService.toBoundingBox(centerLat, centerLng, radiusMeters)
        return ResponseEntity.ok(tileService.getViewportTiles(bounds))
    }
    
    /**
     * Get a specific tile by its H3 ID
     */
    @GetMapping("/{id}")
    fun getTileById(@PathVariable id: String): ResponseEntity<TileService.TileDto> {
        val tile = tileService.getTileById(id)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(tile)
    }
    
    /**
     * Get tile info for a coordinate
     */
    @GetMapping("/at")
    fun getTileAtCoordinate(
        @RequestParam lat: Double,
        @RequestParam lng: Double
    ): ResponseEntity<TileService.TileDto> {
        val tile = tileService.getTileForCoordinate(lat, lng)
        return ResponseEntity.ok(tile)
    }
    
    /**
     * Get all tiles owned by a user (solo)
     */
    @GetMapping("/user/{userId}")
    fun getTilesByUser(@PathVariable userId: UUID): ResponseEntity<List<TileService.TileDto>> {
        return ResponseEntity.ok(tileService.getTilesByUser(userId))
    }
    
    /**
     * Get all tiles owned by a bandeira
     */
    @GetMapping("/bandeira/{bandeiraId}")
    fun getTilesByBandeira(@PathVariable bandeiraId: UUID): ResponseEntity<List<TileService.TileDto>> {
        return ResponseEntity.ok(tileService.getTilesByBandeira(bandeiraId))
    }
    
    /**
     * Get all tiles currently in dispute
     */
    @GetMapping("/disputed")
    fun getDisputedTiles(): ResponseEntity<List<TileService.TileDto>> {
        return ResponseEntity.ok(tileService.getTilesInDispute())
    }
    
    /**
     * Get game statistics
     */
    @GetMapping("/stats")
    fun getStats(): ResponseEntity<TileService.GameStats> {
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
}
