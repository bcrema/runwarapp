package com.runwar.domain.run

import com.runwar.config.GameProperties
import com.runwar.domain.bandeira.Bandeira
import com.runwar.domain.bandeira.BandeiraCategory
import com.runwar.domain.tile.TileRepository
import com.runwar.domain.user.User
import com.runwar.domain.user.UserRepository
import com.runwar.game.LatLngPoint
import com.runwar.game.LoopValidationFlags
import com.runwar.game.LoopValidationMetrics
import com.runwar.game.LoopValidationFlagService
import com.runwar.game.LoopValidator
import com.runwar.game.ShieldMechanics
import com.runwar.geo.GpxParser
import com.runwar.telemetry.RunTelemetryService
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import java.math.BigDecimal
import java.time.Instant
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Test
import java.util.UUID

class RunServiceTest {

    @Test
    fun `getDailyStatus reloads user with bandeira before accessing caps`() {
        val runRepository = mockk<RunRepository>(relaxed = true)
        val gpxParser = mockk<GpxParser>(relaxed = true)
        val loopValidator = mockk<LoopValidator>(relaxed = true)
        val loopValidationFlagService = mockk<LoopValidationFlagService>(relaxed = true)
        val shieldMechanics = mockk<ShieldMechanics>(relaxed = true)
        val tileRepository = mockk<TileRepository>(relaxed = true)
        val capsService = mockk<CapsService>()
        val runTelemetryService = mockk<RunTelemetryService>(relaxed = true)
        val userRepository = mockk<UserRepository>()

        val service = RunService(
            runRepository = runRepository,
            gpxParser = gpxParser,
            loopValidator = loopValidator,
            loopValidationFlagService = loopValidationFlagService,
            shieldMechanics = shieldMechanics,
            gameProperties = GameProperties(userDailyActionCap = 3),
            tileRepository = tileRepository,
            capsService = capsService,
            runTelemetryService = runTelemetryService,
            userRepository = userRepository
        )

        val userId = UUID.randomUUID()
        val detachedUser = User(
            id = userId,
            email = "member@example.com",
            username = "member",
            passwordHash = "hash"
        )
        val creator = User(
            id = UUID.randomUUID(),
            email = "creator@example.com",
            username = "creator",
            passwordHash = "hash"
        )
        val bandeira = Bandeira(
            id = UUID.randomUUID(),
            name = "LigaRun Beta",
            slug = "ligarun-beta",
            category = BandeiraCategory.GRUPO,
            color = "#0088FF",
            createdBy = creator,
            dailyActionCap = 80
        )
        val managedUser = User(
            id = userId,
            email = detachedUser.email,
            username = detachedUser.username,
            passwordHash = detachedUser.passwordHash,
            bandeira = bandeira
        )

        every { userRepository.findByIdWithBandeira(userId) } returns managedUser
        every { capsService.getDailyActionCount(userId) } returns 2
        every { capsService.getBandeiraDailyActionCount(bandeira.id) } returns 11

        val result = service.getDailyStatus(detachedUser)

        assertEquals(2, result.userActionsUsed)
        assertEquals(1, result.userActionsRemaining)
        assertEquals(11, result.bandeiraActionsUsed)
        assertEquals(80, result.bandeiraActionCap)

        verify(exactly = 1) { userRepository.findByIdWithBandeira(userId) }
        verify(exactly = 1) { capsService.getDailyActionCount(userId) }
        verify(exactly = 1) { capsService.getBandeiraDailyActionCount(bandeira.id) }
    }

    @Test
    fun `getDailyStatus throws when user no longer exists`() {
        val runRepository = mockk<RunRepository>(relaxed = true)
        val gpxParser = mockk<GpxParser>(relaxed = true)
        val loopValidator = mockk<LoopValidator>(relaxed = true)
        val loopValidationFlagService = mockk<LoopValidationFlagService>(relaxed = true)
        val shieldMechanics = mockk<ShieldMechanics>(relaxed = true)
        val tileRepository = mockk<TileRepository>(relaxed = true)
        val capsService = mockk<CapsService>(relaxed = true)
        val runTelemetryService = mockk<RunTelemetryService>(relaxed = true)
        val userRepository = mockk<UserRepository>()

        val service = RunService(
            runRepository = runRepository,
            gpxParser = gpxParser,
            loopValidator = loopValidator,
            loopValidationFlagService = loopValidationFlagService,
            shieldMechanics = shieldMechanics,
            gameProperties = GameProperties(),
            tileRepository = tileRepository,
            capsService = capsService,
            runTelemetryService = runTelemetryService,
            userRepository = userRepository
        )

        val userId = UUID.randomUUID()
        val detachedUser = User(
            id = userId,
            email = "missing@example.com",
            username = "missing",
            passwordHash = "hash"
        )

        every { userRepository.findByIdWithBandeira(userId) } returns null

        assertThrows(IllegalArgumentException::class.java) {
            service.getDailyStatus(detachedUser)
        }

        verify(exactly = 0) { capsService.getDailyActionCount(any()) }
    }

    @Test
    fun `submitRunFromCoordinates updates stats and keeps invalid runs without territorial action`() {
        val runRepository = mockk<RunRepository>()
        val gpxParser = mockk<GpxParser>(relaxed = true)
        val loopValidator = mockk<LoopValidator>()
        val loopValidationFlagService = mockk<LoopValidationFlagService>()
        val shieldMechanics = mockk<ShieldMechanics>(relaxed = true)
        val tileRepository = mockk<TileRepository>(relaxed = true)
        val capsService = mockk<CapsService>()
        val runTelemetryService = mockk<RunTelemetryService>(relaxed = true)
        val userRepository = mockk<UserRepository>()

        val user = User(
            id = UUID.randomUUID(),
            email = "runner@example.com",
            username = "runner",
            passwordHash = "hash",
            totalRuns = 0,
            totalDistance = BigDecimal.ZERO
        )

        every { userRepository.findByIdWithBandeira(user.id) } returns user
        every { capsService.checkCaps(user) } returns CapsService.CapsCheck(
            actionsToday = 0,
            bandeiraActionsToday = null,
            userCapReached = false,
            bandeiraCapReached = false
        )
        every { loopValidationFlagService.resolveFlags(null) } returns LoopValidationFlags()
        every { loopValidator.validate(any(), any()) } returns LoopValidator.ValidationResult(
            isLoopValid = false,
            reasons = listOf("distance_too_short"),
            metrics = LoopValidationMetrics(
                loopDistanceMeters = 500.0,
                loopDurationSeconds = 180,
                closureMeters = 120.0,
                coveragePct = 0.35
            ),
            tilesCovered = listOf("8928308280fffff"),
            primaryTile = "8928308280fffff",
            fraudFlags = emptyList()
        )
        every { runRepository.save(any()) } answers { firstArg() }

        val service = RunService(
            runRepository = runRepository,
            gpxParser = gpxParser,
            loopValidator = loopValidator,
            loopValidationFlagService = loopValidationFlagService,
            shieldMechanics = shieldMechanics,
            gameProperties = GameProperties(userDailyActionCap = 3),
            tileRepository = tileRepository,
            capsService = capsService,
            runTelemetryService = runTelemetryService,
            userRepository = userRepository
        )

        val result = service.submitRunFromCoordinates(
            user = user,
            coordinates = listOf(
                LatLngPoint(-25.43, -49.27),
                LatLngPoint(-25.431, -49.271)
            ),
            timestamps = listOf(Instant.now().minusSeconds(180), Instant.now()),
            origin = RunOrigin.IOS
        )

        assertEquals(1, user.totalRuns)
        assertEquals(0, user.totalDistance.compareTo(BigDecimal.valueOf(500.0)))
        assertEquals(0.5, result.run.distance, 0.000001)
        assertEquals(500.0, result.run.distanceMeters, 0.000001)
        assertNotNull(result.run.loopDistance)
        assertNotNull(result.run.loopDistanceMeters)
        assertEquals(0.5, result.run.loopDistance!!, 0.000001)
        assertEquals(500.0, result.run.loopDistanceMeters!!, 0.000001)
        assertNull(result.territoryResult)
        assertNull(result.turnResult.actionType)

        verify(exactly = 0) { shieldMechanics.processAction(any(), any()) }
    }

    @Test
    fun `run dto exposes kilometer and meter distance fields`() {
        val user = User(
            id = UUID.randomUUID(),
            email = "runner@example.com",
            username = "runner",
            passwordHash = "hash"
        )
        val run = Run(
            user = user,
            distance = BigDecimal.valueOf(5230.0),
            duration = 1810,
            startTime = Instant.parse("2026-02-12T10:00:00Z"),
            endTime = Instant.parse("2026-02-12T10:30:10Z"),
            loopDistance = BigDecimal.valueOf(5100.0)
        )

        val dto = RunService.RunDto.from(run)

        assertEquals(5.23, dto.distance, 0.000001)
        assertEquals(5230.0, dto.distanceMeters, 0.000001)
        assertNotNull(dto.loopDistance)
        assertNotNull(dto.loopDistanceMeters)
        assertEquals(5.1, dto.loopDistance!!, 0.000001)
        assertEquals(5100.0, dto.loopDistanceMeters!!, 0.000001)
    }
}
