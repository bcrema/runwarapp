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
    @GetMapping
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
}
