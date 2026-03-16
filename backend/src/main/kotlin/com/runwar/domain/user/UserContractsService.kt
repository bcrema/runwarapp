package com.runwar.domain.user

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

@Service
class UserContractsService(
    private val userContractRepository: UserContractRepository,
    private val objectMapper: ObjectMapper
) {

    data class UserRankingResponse(
        val seasonId: UUID,
        val seasonName: String,
        val scope: String,
        val generatedAt: Instant,
        val entries: List<UserRankingEntry>,
        val currentUserEntry: UserRankingEntry?
    )

    data class UserRankingEntry(
        val position: Int,
        val userId: UUID,
        val username: String,
        val avatarUrl: String?,
        val bandeiraId: UUID?,
        val bandeiraName: String?,
        val dailyPoints: Int,
        val clusterBonus: Int,
        val totalPoints: Int
    )

    data class BadgeResponse(
        val badgeId: UUID,
        val slug: String,
        val name: String,
        val description: String?,
        val iconUrl: String?,
        val earnedAt: Instant?,
        val progress: BadgeProgress
    )

    data class BadgeProgress(
        val criteriaType: String,
        val currentValue: Long,
        val targetValue: Long,
        val unit: String,
        val completed: Boolean
    )

    data class ActiveMissionResponse(
        val missionId: UUID,
        val weekStart: LocalDate,
        val missionType: String,
        val targetValue: Int,
        val currentValue: Int,
        val completed: Boolean
    )

    fun getUserRankings(userId: UUID, scope: String): UserRankingResponse {
        if (scope != "season") {
            throw IllegalArgumentException("Unsupported scope: $scope")
        }

        val season = userContractRepository.findActiveSeason()
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "No active season found")
        val entries = userContractRepository.findSeasonRankingEntries(season.seasonId).map {
            UserRankingEntry(
                position = it.position,
                userId = it.userId,
                username = it.username,
                avatarUrl = it.avatarUrl,
                bandeiraId = it.bandeiraId,
                bandeiraName = it.bandeiraName,
                dailyPoints = it.dailyPoints,
                clusterBonus = it.clusterBonus,
                totalPoints = it.totalPoints
            )
        }

        return UserRankingResponse(
            seasonId = season.seasonId,
            seasonName = season.seasonName,
            scope = scope,
            generatedAt = Instant.now(),
            entries = entries,
            currentUserEntry = entries.firstOrNull { it.userId == userId }
        )
    }

    fun getMyBadges(userId: UUID): List<BadgeResponse> {
        val snapshot = userContractRepository.buildBadgeProgressSnapshot(userId)
        return userContractRepository.findBadgesForUser(userId).map { badge ->
            val criteria = parseCriteria(badge.criteriaJson)
            BadgeResponse(
                badgeId = badge.badgeId,
                slug = badge.slug,
                name = badge.name,
                description = badge.description,
                iconUrl = badge.iconUrl,
                earnedAt = badge.earnedAt,
                progress = buildBadgeProgress(criteria, snapshot, badge.earnedAt != null)
            )
        }
    }

    fun getActiveMissions(userId: UUID): List<ActiveMissionResponse> {
        val weekStart = LocalDate.now(REPORTING_ZONE).with(DayOfWeek.MONDAY)
        return userContractRepository.findActiveMissions(userId, weekStart).map {
            ActiveMissionResponse(
                missionId = it.missionId,
                weekStart = it.weekStart,
                missionType = it.missionType,
                targetValue = it.targetValue,
                currentValue = it.currentValue,
                completed = it.completed
            )
        }
    }

    private fun parseCriteria(criteriaJson: String): JsonNode {
        return objectMapper.readTree(criteriaJson.ifBlank { "{}" })
    }

    private fun buildBadgeProgress(
        criteria: JsonNode,
        snapshot: UserContractRepository.BadgeProgressSnapshot,
        alreadyEarned: Boolean
    ): BadgeProgress {
        val criteriaType = criteria.path("type").asText("unknown")
        val progress =
            when (criteriaType) {
                "conquest" ->
                    BadgeProgress(
                        criteriaType = criteriaType,
                        currentValue = snapshot.conquestCount.toLong(),
                        targetValue = criteria.path("count").asLong(0),
                        unit = "quadras",
                        completed = false
                    )

                "defense_dispute" ->
                    BadgeProgress(
                        criteriaType = criteriaType,
                        currentValue = snapshot.defenseDisputeCount.toLong(),
                        targetValue = criteria.path("count").asLong(0),
                        unit = "defenses",
                        completed = false
                    )

                "attack" ->
                    BadgeProgress(
                        criteriaType = criteriaType,
                        currentValue = snapshot.attackCount.toLong(),
                        targetValue = criteria.path("count").asLong(0),
                        unit = "attacks",
                        completed = false
                    )

                "distance" ->
                    BadgeProgress(
                        criteriaType = criteriaType,
                        currentValue = snapshot.distanceMeters,
                        targetValue = criteria.path("meters").asLong(0),
                        unit = "meters",
                        completed = false
                    )

                "streak" ->
                    BadgeProgress(
                        criteriaType = criteriaType,
                        currentValue = snapshot.streakDays.toLong(),
                        targetValue = criteria.path("days").asLong(0),
                        unit = "days",
                        completed = false
                    )

                else ->
                    BadgeProgress(
                        criteriaType = criteriaType,
                        currentValue = 0,
                        targetValue = 0,
                        unit = "count",
                        completed = false
                    )
            }

        return progress.copy(
            completed = alreadyEarned || (progress.targetValue > 0 && progress.currentValue >= progress.targetValue)
        )
    }

    companion object {
        private val REPORTING_ZONE: ZoneId = ZoneId.of("America/Sao_Paulo")
    }
}
