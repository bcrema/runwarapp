package com.runwar.domain.bandeira

import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

@Service
class BandeiraPresenceService(
    private val bandeiraRepository: BandeiraRepository,
    private val bandeiraPresenceRepository: BandeiraPresenceRepository
) {

    data class WeeklyPresenceResponse(
        val bandeiraId: UUID,
        val period: String,
        val timezone: String,
        val weekStart: LocalDate,
        val weekEnd: LocalDate,
        val generatedAt: Instant,
        val summary: WeeklyPresenceSummary,
        val members: List<WeeklyPresenceMember>
    )

    data class WeeklyPresenceSummary(
        val activeMembers: Int,
        val totalMembers: Int,
        val runsCount: Int,
        val distanceMeters: Double
    )

    data class WeeklyPresenceMember(
        val userId: UUID,
        val username: String,
        val avatarUrl: String?,
        val runsCount: Int,
        val distanceMeters: Double,
        val lastRunAt: Instant?,
        val presenceState: String
    )

    fun getPresence(bandeiraId: UUID, period: String): WeeklyPresenceResponse {
        if (period != "week") {
            throw IllegalArgumentException("Unsupported period: $period")
        }
        if (!bandeiraRepository.existsById(bandeiraId)) {
            throw ResponseStatusException(HttpStatus.NOT_FOUND, "Bandeira not found")
        }

        val today = LocalDate.now(REPORTING_ZONE)
        val weekStart = today.with(DayOfWeek.MONDAY)
        val weekEnd = weekStart.plusDays(6)
        val weekStartInstant = weekStart.atStartOfDay(REPORTING_ZONE).toInstant()
        val weekEndExclusive = weekEnd.plusDays(1).atStartOfDay(REPORTING_ZONE).toInstant()

        val members = bandeiraPresenceRepository.findWeeklyPresenceMembers(
            bandeiraId = bandeiraId,
            weekStart = weekStartInstant,
            weekEndExclusive = weekEndExclusive
        ).map {
            WeeklyPresenceMember(
                userId = it.userId,
                username = it.username,
                avatarUrl = it.avatarUrl,
                runsCount = it.runsCount,
                distanceMeters = it.distanceMeters,
                lastRunAt = it.lastRunAt,
                presenceState = if (it.runsCount > 0) "ACTIVE" else "INACTIVE"
            )
        }

        return WeeklyPresenceResponse(
            bandeiraId = bandeiraId,
            period = period,
            timezone = REPORTING_ZONE.id,
            weekStart = weekStart,
            weekEnd = weekEnd,
            generatedAt = Instant.now(),
            summary = WeeklyPresenceSummary(
                activeMembers = members.count { it.presenceState == "ACTIVE" },
                totalMembers = members.size,
                runsCount = members.sumOf { it.runsCount },
                distanceMeters = members.sumOf { it.distanceMeters }
            ),
            members = members
        )
    }

    companion object {
        private val REPORTING_ZONE: ZoneId = ZoneId.of("America/Sao_Paulo")
    }
}
