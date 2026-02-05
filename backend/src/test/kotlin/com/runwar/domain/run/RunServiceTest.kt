package com.runwar.domain.run

import com.runwar.config.GameProperties
import com.runwar.domain.bandeira.Bandeira
import com.runwar.domain.bandeira.BandeiraCategory
import com.runwar.domain.tile.TileRepository
import com.runwar.domain.user.User
import com.runwar.domain.user.UserRepository
import com.runwar.game.LoopValidationFlagService
import com.runwar.game.LoopValidator
import com.runwar.game.ShieldMechanics
import com.runwar.geo.GpxParser
import com.runwar.telemetry.RunTelemetryService
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Assertions.assertEquals
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
}
