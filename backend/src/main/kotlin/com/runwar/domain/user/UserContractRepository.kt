package com.runwar.domain.user

import java.math.BigDecimal
import java.sql.Timestamp
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate
import org.springframework.stereotype.Repository

@Repository
class UserContractRepository(
    private val jdbcTemplate: NamedParameterJdbcTemplate
) {

    data class ActiveSeasonRow(
        val seasonId: UUID,
        val seasonName: String
    )

    data class SeasonRankingEntryRow(
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

    data class BadgeRow(
        val badgeId: UUID,
        val slug: String,
        val name: String,
        val description: String?,
        val iconUrl: String?,
        val criteriaJson: String,
        val earnedAt: Instant?
    )

    data class BadgeProgressSnapshot(
        val conquestCount: Int,
        val attackCount: Int,
        val defenseDisputeCount: Int,
        val distanceMeters: Long,
        val streakDays: Int
    )

    data class ActiveMissionRow(
        val missionId: UUID,
        val weekStart: LocalDate,
        val missionType: String,
        val targetValue: Int,
        val currentValue: Int,
        val completed: Boolean
    )

    fun findActiveSeason(): ActiveSeasonRow? {
        val sql =
            """
            SELECT id, name
            FROM seasons
            WHERE is_active = true
            ORDER BY start_date DESC, created_at DESC
            LIMIT 1
            """.trimIndent()

        return jdbcTemplate.query(sql, emptyMap<String, Any>()) { rs, _ ->
            ActiveSeasonRow(
                seasonId = rs.getObject("id", UUID::class.java),
                seasonName = rs.getString("name")
            )
        }.firstOrNull()
    }

    fun findSeasonRankingEntries(seasonId: UUID): List<SeasonRankingEntryRow> {
        val sql =
            """
            WITH ranked_scores AS (
                SELECT
                    ss.*,
                    ROW_NUMBER() OVER (
                        PARTITION BY ss.user_id
                        ORDER BY ss.date DESC, ss.created_at DESC, ss.total_points DESC
                    ) AS snapshot_rank
                FROM season_scores ss
                WHERE ss.season_id = :seasonId
                  AND ss.score_type = 'SOLO'
                  AND ss.user_id IS NOT NULL
            )
            SELECT
                ROW_NUMBER() OVER (
                    ORDER BY rs.total_points DESC, rs.daily_points DESC, u.username ASC
                ) AS position,
                u.id AS user_id,
                u.username,
                u.avatar_url,
                b.id AS bandeira_id,
                b.name AS bandeira_name,
                rs.daily_points,
                rs.cluster_bonus,
                rs.total_points
            FROM ranked_scores rs
            JOIN users u
              ON u.id = rs.user_id
            LEFT JOIN bandeiras b
              ON b.id = u.bandeira_id
            WHERE rs.snapshot_rank = 1
            ORDER BY rs.total_points DESC, rs.daily_points DESC, u.username ASC
            """.trimIndent()

        val params = mapOf("seasonId" to seasonId)
        return jdbcTemplate.query(sql, params) { rs, _ ->
            SeasonRankingEntryRow(
                position = rs.getInt("position"),
                userId = rs.getObject("user_id", UUID::class.java),
                username = rs.getString("username"),
                avatarUrl = rs.getString("avatar_url"),
                bandeiraId = rs.getObject("bandeira_id", UUID::class.java),
                bandeiraName = rs.getString("bandeira_name"),
                dailyPoints = rs.getInt("daily_points"),
                clusterBonus = rs.getInt("cluster_bonus"),
                totalPoints = rs.getInt("total_points")
            )
        }
    }

    fun findBadgesForUser(userId: UUID): List<BadgeRow> {
        val sql =
            """
            SELECT
                b.id AS badge_id,
                b.slug,
                b.name,
                b.description,
                b.icon_url,
                CAST(b.criteria AS VARCHAR) AS criteria_json,
                ub.earned_at
            FROM badges b
            LEFT JOIN user_badges ub
              ON ub.badge_id = b.id
             AND ub.user_id = :userId
            ORDER BY b.created_at ASC, b.slug ASC
            """.trimIndent()

        return jdbcTemplate.query(sql, mapOf("userId" to userId)) { rs, _ ->
            BadgeRow(
                badgeId = rs.getObject("badge_id", UUID::class.java),
                slug = rs.getString("slug"),
                name = rs.getString("name"),
                description = rs.getString("description"),
                iconUrl = rs.getString("icon_url"),
                criteriaJson = rs.getString("criteria_json") ?: "{}",
                earnedAt = rs.getTimestamp("earned_at")?.toInstant()
            )
        }
    }

    fun buildBadgeProgressSnapshot(userId: UUID): BadgeProgressSnapshot {
        val userSql =
            """
            SELECT
                COALESCE(total_quadras_conquered, 0) AS conquest_count,
                COALESCE(total_distance, 0) AS distance_meters
            FROM users
            WHERE id = :userId
            """.trimIndent()
        val userParams = mapOf("userId" to userId)
        val userStats =
            jdbcTemplate.query(userSql, userParams) { rs, _ ->
                Pair(
                    rs.getInt("conquest_count"),
                    (rs.getBigDecimal("distance_meters") ?: BigDecimal.ZERO).toDouble().toLong()
                )
            }.firstOrNull() ?: Pair(0, 0L)

        val actionsSql =
            """
            SELECT
                COALESCE(SUM(CASE WHEN action_type = 'ATTACK' THEN 1 ELSE 0 END), 0) AS attack_count,
                COALESCE(
                    SUM(
                        CASE
                            WHEN action_type = 'DEFENSE' AND shield_before < 70 THEN 1
                            ELSE 0
                        END
                    ),
                    0
                ) AS defense_dispute_count
            FROM territory_actions
            WHERE user_id = :userId
            """.trimIndent()
        val actionStats =
            jdbcTemplate.query(actionsSql, userParams) { rs, _ ->
                Pair(rs.getInt("attack_count"), rs.getInt("defense_dispute_count"))
            }.firstOrNull() ?: Pair(0, 0)

        return BadgeProgressSnapshot(
            conquestCount = userStats.first,
            attackCount = actionStats.first,
            defenseDisputeCount = actionStats.second,
            distanceMeters = userStats.second,
            streakDays = findBestRunStreakDays(userId)
        )
    }

    fun findActiveMissions(userId: UUID, weekStart: LocalDate): List<ActiveMissionRow> {
        val sql =
            """
            SELECT id, week_start, mission_type, target_value, current_value, completed
            FROM weekly_missions
            WHERE user_id = :userId
              AND week_start = :weekStart
            ORDER BY created_at ASC, mission_type ASC
            """.trimIndent()

        val params = MapSqlParameterSource()
            .addValue("userId", userId)
            .addValue("weekStart", weekStart)

        return jdbcTemplate.query(sql, params) { rs, _ ->
            ActiveMissionRow(
                missionId = rs.getObject("id", UUID::class.java),
                weekStart = rs.getObject("week_start", LocalDate::class.java),
                missionType = rs.getString("mission_type"),
                targetValue = rs.getInt("target_value"),
                currentValue = rs.getInt("current_value"),
                completed = rs.getBoolean("completed")
            )
        }
    }

    private fun findBestRunStreakDays(userId: UUID): Int {
        val sql =
            """
            SELECT CAST(start_time AT TIME ZONE 'America/Sao_Paulo' AS DATE) AS run_date
            FROM runs
            WHERE user_id = :userId
            GROUP BY CAST(start_time AT TIME ZONE 'America/Sao_Paulo' AS DATE)
            ORDER BY run_date DESC
            """.trimIndent()

        val runDates =
            jdbcTemplate.query(sql, mapOf("userId" to userId)) { rs, _ ->
                rs.getObject("run_date", LocalDate::class.java)
            }

        if (runDates.isEmpty()) {
            return 0
        }

        var best = 1
        var current = 1
        for (index in 1 until runDates.size) {
            val previous = runDates[index - 1]
            val currentDate = runDates[index]
            if (currentDate.plusDays(1) == previous) {
                current += 1
                best = maxOf(best, current)
            } else {
                current = 1
            }
        }

        return best
    }
}
