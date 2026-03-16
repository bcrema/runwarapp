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

    data class DevicePushTokenRow(
        val userId: UUID,
        val deviceId: String,
        val platform: String,
        val token: String,
        val appVersion: String?,
        val updatedAt: Instant
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

    fun findDevicePushToken(userId: UUID, deviceId: String): DevicePushTokenRow? {
        val sql =
            """
            SELECT user_id, device_id, platform, token, app_version, updated_at
            FROM device_push_tokens
            WHERE user_id = :userId
              AND device_id = :deviceId
            """.trimIndent()

        return jdbcTemplate.query(
            sql,
            mapOf("userId" to userId, "deviceId" to deviceId)
        ) { rs, _ ->
            DevicePushTokenRow(
                userId = rs.getObject("user_id", UUID::class.java),
                deviceId = rs.getString("device_id"),
                platform = rs.getString("platform"),
                token = rs.getString("token"),
                appVersion = rs.getString("app_version"),
                updatedAt = rs.getTimestamp("updated_at").toInstant()
            )
        }.firstOrNull()
    }

    fun insertDevicePushToken(
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

    fun updateDevicePushToken(
        userId: UUID,
        deviceId: String,
        platform: String,
        token: String,
        appVersion: String?,
        updatedAt: Instant
    ) {
        val sql =
            """
            UPDATE device_push_tokens
            SET platform = :platform,
                token = :token,
                app_version = :appVersion,
                updated_at = :updatedAt
            WHERE user_id = :userId
              AND device_id = :deviceId
            """.trimIndent()

        val params = MapSqlParameterSource()
            .addValue("userId", userId)
            .addValue("deviceId", deviceId)
            .addValue("platform", platform)
            .addValue("token", token)
            .addValue("appVersion", appVersion)
            .addValue("updatedAt", Timestamp.from(updatedAt))

        jdbcTemplate.update(sql, params)
    }
}
