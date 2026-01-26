package com.runwar.game

import com.runwar.config.GameProperties
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class H3GridServiceTest {

    @Test
    fun `resolution defaults to ~250m radius`() {
        val service = H3GridService(GameProperties(h3TargetRadiusMeters = 250.0))

        assertEquals(8, service.resolution)
    }

    @Test
    fun `calculateTileCoverage keeps single-tile tracks in same tile`() {
        val service = H3GridService(GameProperties(h3Resolution = 8))
        val base = LatLngPoint(-25.45, -49.25)
        val tileId = service.getTileId(base.lat, base.lng)
        val center = service.getTileCenter(tileId)

        val track = listOf(
            LatLngPoint(center.lat + 0.0003, center.lng),
            LatLngPoint(center.lat, center.lng + 0.0003)
        )

        val coverage = service.calculateTileCoverage(track)

        assertEquals(1, coverage.size)
        assertTrue(coverage.containsKey(tileId))
        assertEquals(1.0, coverage[tileId]!!, 1e-6)
    }

    @Test
    fun `primary tile returns overlay and coverage`() {
        val service = H3GridService(GameProperties(h3Resolution = 8))
        val base = LatLngPoint(-25.45, -49.25)
        val tileId = service.getTileId(base.lat, base.lng)
        val center = service.getTileCenter(tileId)

        val track = listOf(
            LatLngPoint(center.lat + 0.0003, center.lng),
            LatLngPoint(center.lat, center.lng + 0.0003)
        )

        val result = service.getPrimaryTileForTrack(track)

        assertNotNull(result)
        assertEquals(tileId, result!!.tileId)
        assertEquals(1.0, result.coverage, 1e-6)
        assertTrue(result.boundary.size >= 5)
    }
}
