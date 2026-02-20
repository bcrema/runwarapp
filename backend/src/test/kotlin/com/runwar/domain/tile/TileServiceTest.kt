package com.runwar.domain.tile

import com.runwar.config.GameProperties
import com.runwar.domain.bandeira.BandeiraRepository
import com.runwar.domain.user.UserRepository
import com.runwar.game.H3GridService
import com.runwar.game.LatLngPoint
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.locationtech.jts.geom.Coordinate
import org.locationtech.jts.geom.GeometryFactory
import org.locationtech.jts.geom.PrecisionModel
import org.springframework.transaction.annotation.Transactional
import java.util.Optional

class TileServiceTest {

    @Test
    fun `tile service is marked as read only transactional`() {
        val transactional = TileService::class.java.getAnnotation(Transactional::class.java)

        assertNotNull(transactional)
        assertTrue(transactional.readOnly)
    }

    @Test
    fun `toBoundingBox converts radius to bounds`() {
        val service = TileService(
            tileRepository = mockk(relaxed = true),
            userRepository = mockk(relaxed = true),
            bandeiraRepository = mockk(relaxed = true),
            h3GridService = mockk(relaxed = true),
            gameProperties = GameProperties()
        )

        val bbox = service.toBoundingBox(centerLat = 0.0, centerLng = 0.0, radiusMeters = 111_320.0)

        assertEquals(-1.0, bbox.minLat, 1e-6)
        assertEquals(1.0, bbox.maxLat, 1e-6)
        assertEquals(-1.0, bbox.minLng, 1e-6)
        assertEquals(1.0, bbox.maxLng, 1e-6)
    }

    @Test
    fun `getTileForCoordinate returns neutral tile info when unclaimed`() {
        val tileRepository = mockk<TileRepository>()
        val h3GridService = mockk<H3GridService>()

        every { h3GridService.getTileId(10.0, 20.0) } returns "tile-1"
        every { tileRepository.findById("tile-1") } returns Optional.empty()
        every { h3GridService.getTileCenter("tile-1") } returns LatLngPoint(1.0, 2.0)
        every { h3GridService.getTileBoundary("tile-1") } returns listOf(
            LatLngPoint(1.0, 2.0),
            LatLngPoint(3.0, 4.0)
        )

        val service = TileService(
            tileRepository = tileRepository,
            userRepository = mockk(relaxed = true),
            bandeiraRepository = mockk(relaxed = true),
            h3GridService = h3GridService,
            gameProperties = GameProperties()
        )

        val dto = service.getTileForCoordinate(10.0, 20.0)

        assertEquals("tile-1", dto.id)
        assertEquals(1.0, dto.lat)
        assertEquals(2.0, dto.lng)
        assertNull(dto.ownerType)
        assertNull(dto.ownerId)
        assertNull(dto.ownerName)
        assertEquals(0, dto.shield)
        assertTrue(dto.boundary.size == 2)
    }

    @Test
    fun `getViewportTiles caches within ttl`() {
        val tileRepository = mockk<TileRepository>()
        val userRepository = mockk<UserRepository>(relaxed = true)
        val bandeiraRepository = mockk<BandeiraRepository>(relaxed = true)
        val h3GridService = mockk<H3GridService>()

        every { h3GridService.resolution } returns 8

        val geometryFactory = GeometryFactory(PrecisionModel(), 4326)
        val tile = Tile(
            id = "tile-1",
            center = geometryFactory.createPoint(Coordinate(0.0, 0.0)),
            ownerType = null,
            ownerId = null,
            shield = 10
        )

        every { tileRepository.findTilesInBoundingBox(any(), any(), any(), any()) } returns listOf(tile)

        val service = TileService(
            tileRepository = tileRepository,
            userRepository = userRepository,
            bandeiraRepository = bandeiraRepository,
            h3GridService = h3GridService,
            gameProperties = GameProperties(disputeThreshold = 70)
        )

        val bounds = TileService.BoundingBox(
            minLng = -49.0,
            minLat = -25.0,
            maxLng = -48.0,
            maxLat = -24.0
        )

        service.getViewportTiles(bounds)
        service.getViewportTiles(bounds)

        verify(exactly = 1) { tileRepository.findTilesInBoundingBox(any(), any(), any(), any()) }
        verify(exactly = 0) { bandeiraRepository.findAllById(any<Iterable<java.util.UUID>>()) }
    }
}
