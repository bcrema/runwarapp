package com.runwar.domain.user

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import java.time.LocalDate
import java.util.UUID

class UserContractsServiceTest {

    private val userContractRepository = mockk<UserContractRepository>()
    private val service = UserContractsService(userContractRepository, jacksonObjectMapper())

    @Test
    fun `get user rankings exposes current user entry`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        val seasonId = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
        every { userContractRepository.findActiveSeason() } returns
            UserContractRepository.ActiveSeasonRow(seasonId, "Temporada 1")
        every { userContractRepository.findSeasonRankingEntries(seasonId) } returns listOf(
            UserContractRepository.SeasonRankingEntryRow(
                position = 1,
                userId = userId,
                username = "runner",
                avatarUrl = null,
                bandeiraId = null,
                bandeiraName = null,
                dailyPoints = 10,
                clusterBonus = 4,
                totalPoints = 14
            )
        )

        val response = service.getUserRankings(userId, "season")

        assertEquals(seasonId, response.seasonId)
        assertEquals("Temporada 1", response.seasonName)
        assertEquals(userId, response.currentUserEntry?.userId)
        assertEquals(14, response.entries.single().totalPoints)
    }

    @Test
    fun `get my badges converts criteria into progress`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { userContractRepository.buildBadgeProgressSnapshot(userId) } returns
            UserContractRepository.BadgeProgressSnapshot(
                conquestCount = 2,
                attackCount = 4,
                defenseDisputeCount = 1,
                distanceMeters = 5600,
                streakDays = 3
            )
        every { userContractRepository.findBadgesForUser(userId) } returns listOf(
            UserContractRepository.BadgeRow(
                badgeId = UUID.fromString("22222222-2222-2222-2222-222222222222"),
                slug = "marathon",
                name = "Maratonista",
                description = "10km",
                iconUrl = null,
                criteriaJson = """{"type":"distance","meters":10000}""",
                earnedAt = null
            )
        )

        val badges = service.getMyBadges(userId)

        assertEquals(1, badges.size)
        assertEquals("distance", badges.single().progress.criteriaType)
        assertEquals(5600, badges.single().progress.currentValue)
        assertEquals(10000, badges.single().progress.targetValue)
        assertFalse(badges.single().progress.completed)
    }

    @Test
    fun `get active missions maps repository rows`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { userContractRepository.findActiveMissions(eq(userId), any()) } returns listOf(
            UserContractRepository.ActiveMissionRow(
                missionId = UUID.fromString("33333333-3333-3333-3333-333333333333"),
                weekStart = LocalDate.parse("2026-03-16"),
                missionType = "distance",
                targetValue = 15000,
                currentValue = 8400,
                completed = false
            )
        )

        val missions = service.getActiveMissions(userId)

        assertEquals(1, missions.size)
        assertEquals("distance", missions.single().missionType)
        assertNotNull(missions.single().weekStart)
    }
}
