package com.runwar.domain.bandeira

import java.math.BigDecimal
import java.sql.Timestamp
import java.time.Instant
import java.util.UUID
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate
import org.springframework.stereotype.Repository

@Repository
class BandeiraPresenceRepository(
    private val jdbcTemplate: NamedParameterJdbcTemplate
) {

    data class WeeklyPresenceMemberRow(
        val userId: UUID,
        val username: String,
        val avatarUrl: String?,
        val runsCount: Int,
        val distanceMeters: Double,
        val lastRunAt: Instant?
    )

    fun findWeeklyPresenceMembers(
        bandeiraId: UUID,
        weekStart: Instant,
        weekEndExclusive: Instant
    ): List<WeeklyPresenceMemberRow> {
        val sql =
            """
            SELECT
                u.id AS user_id,
                u.username,
                u.avatar_url,
                COALESCE(activity.runs_count, 0) AS runs_count,
                COALESCE(activity.distance_meters, 0) AS distance_meters,
                activity.last_run_at
            FROM users u
            LEFT JOIN (
                SELECT
                    r.user_id,
                    COUNT(*) AS runs_count,
                    COALESCE(SUM(r.distance), 0) AS distance_meters,
                    MAX(r.end_time) AS last_run_at
                FROM runs r
                JOIN users ru
                  ON ru.id = r.user_id
                WHERE ru.bandeira_id = :bandeiraId
                  AND r.start_time >= :weekStart
                  AND r.start_time < :weekEndExclusive
                GROUP BY r.user_id
            ) activity
              ON activity.user_id = u.id
            WHERE u.bandeira_id = :bandeiraId
            ORDER BY COALESCE(activity.distance_meters, 0) DESC,
                     COALESCE(activity.runs_count, 0) DESC,
                     u.username ASC
            """.trimIndent()

        val params = MapSqlParameterSource()
            .addValue("bandeiraId", bandeiraId)
            .addValue("weekStart", Timestamp.from(weekStart))
            .addValue("weekEndExclusive", Timestamp.from(weekEndExclusive))

        return jdbcTemplate.query(sql, params) { rs, _ ->
            WeeklyPresenceMemberRow(
                userId = rs.getObject("user_id", UUID::class.java),
                username = rs.getString("username"),
                avatarUrl = rs.getString("avatar_url"),
                runsCount = rs.getInt("runs_count"),
                distanceMeters = (rs.getBigDecimal("distance_meters") ?: BigDecimal.ZERO).toDouble(),
                lastRunAt = rs.getTimestamp("last_run_at")?.toInstant()
            )
        }
    }
}
