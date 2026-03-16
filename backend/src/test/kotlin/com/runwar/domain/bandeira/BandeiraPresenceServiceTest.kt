package com.runwar.domain.bandeira

import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class BandeiraPresenceServiceTest {

    private val bandeiraRepository = mockk<BandeiraRepository>()
    private val bandeiraPresenceRepository = mockk<BandeiraPresenceRepository>()
    private val service = BandeiraPresenceService(bandeiraRepository, bandeiraPresenceRepository)

    @Test
    fun `get presence aggregates active and inactive members`() {
        val bandeiraId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { bandeiraRepository.existsById(bandeiraId) } returns true
        every { bandeiraPresenceRepository.findWeeklyPresenceMembers(eq(bandeiraId), any(), any()) } returns listOf(
            BandeiraPresenceRepository.WeeklyPresenceMemberRow(
                userId = UUID.fromString("22222222-2222-2222-2222-222222222222"),
                username = "alice",
                avatarUrl = null,
                runsCount = 2,
                distanceMeters = 8000.0,
                lastRunAt = Instant.parse("2026-03-16T09:00:00Z")
            ),
            BandeiraPresenceRepository.WeeklyPresenceMemberRow(
                userId = UUID.fromString("33333333-3333-3333-3333-333333333333"),
                username = "bob",
                avatarUrl = null,
                runsCount = 0,
                distanceMeters = 0.0,
                lastRunAt = null
            )
        )

        val response = service.getPresence(bandeiraId, "week")

        assertEquals(2, response.summary.totalMembers)
        assertEquals(1, response.summary.activeMembers)
        assertEquals(2, response.summary.runsCount)
        assertEquals("ACTIVE", response.members.first().presenceState)
        assertEquals("INACTIVE", response.members.last().presenceState)
    }
}
