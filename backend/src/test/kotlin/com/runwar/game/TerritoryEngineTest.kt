package com.runwar.game

import com.runwar.domain.run.Run
import com.runwar.domain.run.TerritoryActionType
import com.runwar.domain.tile.OwnerType
import com.runwar.domain.tile.Tile
import com.runwar.domain.tile.TileRepository
import com.runwar.domain.territory.TerritoryAction
import com.runwar.domain.territory.TerritoryActionRepository
import com.runwar.domain.user.User
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.locationtech.jts.geom.Coordinate
import org.locationtech.jts.geom.GeometryFactory
import java.math.BigDecimal
import java.time.Duration
import java.time.Instant
import java.util.UUID

class TerritoryEngineTest {
    private val geometryFactory = GeometryFactory()

    @Test
    fun `neutral tile leads to conquest`() {
        val tileRepository = mockk<TileRepository>()
        val actionRepository = mockk<TerritoryActionRepository>()
        val engine = TerritoryEngine(tileRepository, actionRepository)

        val actor = createUser()
        val tile = createTile()
        val run = createRun(actor)

        val savedTile = slot<Tile>()
        val savedAction = slot<TerritoryAction>()
        every { tileRepository.save(capture(savedTile)) } answers { savedTile.captured }
        every { actionRepository.save(capture(savedAction)) } answers { savedAction.captured }

        val result = engine.applyAction(run, tile, actor)

        assertEquals(TerritoryActionType.CONQUEST, result.actionType)
        assertTrue(result.ownerChanged)
        assertEquals(0, result.shieldBefore)
        assertEquals(100, result.shieldAfter)
        assertFalse(result.inDispute)
        assertEquals(actor.id, savedTile.captured.ownerId)
        assertEquals(OwnerType.SOLO, savedTile.captured.ownerType)
        assertEquals(100, savedTile.captured.shield)
        assertEquals(100, savedAction.captured.shieldAfter)
    }

    @Test
    fun `rival tile leads to attack`() {
        val tileRepository = mockk<TileRepository>()
        val actionRepository = mockk<TerritoryActionRepository>()
        val engine = TerritoryEngine(tileRepository, actionRepository)

        val actor = createUser()
        val rival = createUser()
        val tile = createTile(
            ownerId = rival.id,
            ownerType = OwnerType.SOLO,
            shield = 80
        )
        val run = createRun(actor)

        val savedTile = slot<Tile>()
        val savedAction = slot<TerritoryAction>()
        every { tileRepository.save(capture(savedTile)) } answers { savedTile.captured }
        every { actionRepository.save(capture(savedAction)) } answers { savedAction.captured }

        val result = engine.applyAction(run, tile, actor)

        assertEquals(TerritoryActionType.ATTACK, result.actionType)
        assertFalse(result.ownerChanged)
        assertEquals(80, result.shieldBefore)
        assertEquals(45, result.shieldAfter)
        assertTrue(result.inDispute)
        assertEquals(rival.id, savedTile.captured.ownerId)
        assertEquals(45, savedTile.captured.shield)
        assertEquals(-35, savedAction.captured.shieldChange)
    }

    @Test
    fun `owner tile leads to defense`() {
        val tileRepository = mockk<TileRepository>()
        val actionRepository = mockk<TerritoryActionRepository>()
        val engine = TerritoryEngine(tileRepository, actionRepository)

        val actor = createUser()
        val tile = createTile(
            ownerId = actor.id,
            ownerType = OwnerType.SOLO,
            shield = 60
        )
        val run = createRun(actor)

        val savedTile = slot<Tile>()
        val savedAction = slot<TerritoryAction>()
        every { tileRepository.save(capture(savedTile)) } answers { savedTile.captured }
        every { actionRepository.save(capture(savedAction)) } answers { savedAction.captured }

        val result = engine.applyAction(run, tile, actor)

        assertEquals(TerritoryActionType.DEFENSE, result.actionType)
        assertFalse(result.ownerChanged)
        assertEquals(80, result.shieldAfter)
        assertFalse(result.inDispute)
        assertEquals(20, savedAction.captured.shieldChange)
    }

    @Test
    fun `attack that breaks shield transfers ownership with cooldown`() {
        val tileRepository = mockk<TileRepository>()
        val actionRepository = mockk<TerritoryActionRepository>()
        val engine = TerritoryEngine(tileRepository, actionRepository)

        val actor = createUser()
        val rival = createUser()
        val tile = createTile(
            ownerId = rival.id,
            ownerType = OwnerType.SOLO,
            shield = 30
        )
        val run = createRun(actor)

        val savedTile = slot<Tile>()
        val savedAction = slot<TerritoryAction>()
        every { tileRepository.save(capture(savedTile)) } answers { savedTile.captured }
        every { actionRepository.save(capture(savedAction)) } answers { savedAction.captured }

        val before = Instant.now()
        val result = engine.applyAction(run, tile, actor)

        assertEquals(TerritoryActionType.ATTACK, result.actionType)
        assertTrue(result.ownerChanged)
        assertEquals(65, result.shieldAfter)
        assertEquals(actor.id, savedTile.captured.ownerId)
        assertEquals(OwnerType.SOLO, savedTile.captured.ownerType)
        assertNotNull(result.cooldownUntil)
        val cooldown = result.cooldownUntil!!
        val maxExpected = before.plus(Duration.ofHours(18)).plusSeconds(5)
        assertTrue(cooldown.isAfter(before))
        assertTrue(cooldown.isBefore(maxExpected))
        assertEquals(35, savedAction.captured.shieldChange)
    }

    private fun createTile(
        ownerId: UUID? = null,
        ownerType: OwnerType? = null,
        shield: Int = 0
    ): Tile {
        return Tile(
            id = "tile-1",
            center = geometryFactory.createPoint(Coordinate(0.0, 0.0)),
            ownerType = ownerType,
            ownerId = ownerId,
            shield = shield
        )
    }

    private fun createUser(): User {
        val id = UUID.randomUUID()
        return User(
            id = id,
            email = "user-$id@example.com",
            username = "user-$id",
            passwordHash = "hash"
        )
    }

    private fun createRun(user: User): Run {
        return Run(
            user = user,
            distance = BigDecimal.ONE,
            duration = 1,
            startTime = Instant.now(),
            endTime = Instant.now()
        )
    }
}
