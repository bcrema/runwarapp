package com.runwar.notification

import java.sql.Timestamp
import java.time.Instant
import java.util.UUID
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate
import org.springframework.stereotype.Repository

@Repository
class NotificationContractsRepository(
    private val jdbcTemplate: NamedParameterJdbcTemplate
) {

    data class NotificationRow(
        val id: UUID,
        val type: String,
        val title: String,
        val body: String?,
        val dataJson: String,
        val read: Boolean,
        val createdAt: Instant
    )

    fun findNotifications(
        userId: UUID,
        cursorCreatedAt: Instant?,
        cursorId: UUID?,
        limit: Int
    ): List<NotificationRow> {
        val sql =
            buildString {
                append(
                    """
                    SELECT id, type, title, body, CAST(data AS VARCHAR) AS data_json, read, created_at
                    FROM notifications
                    WHERE user_id = :userId
                    """.trimIndent()
                )
                if (cursorCreatedAt != null && cursorId != null) {
                    append(
                        """

                        AND (
                            created_at < :cursorCreatedAt
                            OR (created_at = :cursorCreatedAt AND id < :cursorId)
                        )
                        """.trimIndent()
                    )
                }
                append(
                    """

                    ORDER BY created_at DESC, id DESC
                    LIMIT :limit
                    """.trimIndent()
                )
            }

        val params = MapSqlParameterSource()
            .addValue("userId", userId)
            .addValue("limit", limit)

        if (cursorCreatedAt != null && cursorId != null) {
            params.addValue("cursorCreatedAt", Timestamp.from(cursorCreatedAt))
            params.addValue("cursorId", cursorId)
        }

        return jdbcTemplate.query(sql, params) { rs, _ ->
            NotificationRow(
                id = rs.getObject("id", UUID::class.java),
                type = rs.getString("type"),
                title = rs.getString("title"),
                body = rs.getString("body"),
                dataJson = rs.getString("data_json") ?: "{}",
                read = rs.getBoolean("read"),
                createdAt = rs.getTimestamp("created_at").toInstant()
            )
        }
    }

    fun upsertDevicePushToken(
        id: UUID,
        userId: UUID,
        deviceId: String,
        platform: String,
        token: String,
        appVersion: String?,
        createdAt: Instant,
        updatedAt: Instant
    ) {
        val sql =
            """
            INSERT INTO device_push_tokens (
                id, user_id, device_id, platform, token, app_version, created_at, updated_at
            ) VALUES (
                :id, :userId, :deviceId, :platform, :token, :appVersion, :createdAt, :updatedAt
            )
            ON CONFLICT (user_id, device_id)
            DO UPDATE SET
                platform = EXCLUDED.platform,
                token = EXCLUDED.token,
                app_version = EXCLUDED.app_version,
                updated_at = EXCLUDED.updated_at
            """.trimIndent()

        val params = MapSqlParameterSource()
            .addValue("id", id)
            .addValue("userId", userId)
            .addValue("deviceId", deviceId)
            .addValue("platform", platform)
            .addValue("token", token)
            .addValue("appVersion", appVersion)
            .addValue("createdAt", Timestamp.from(createdAt))
            .addValue("updatedAt", Timestamp.from(updatedAt))

        jdbcTemplate.update(sql, params)
    }
}
