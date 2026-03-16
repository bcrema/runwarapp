package com.runwar.notification

import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import jakarta.transaction.Transactional
import java.nio.charset.StandardCharsets
import java.time.Instant
import java.util.Base64
import java.util.UUID
import org.springframework.stereotype.Service

@Service
class NotificationContractsService(
    private val notificationContractsRepository: NotificationContractsRepository,
    private val objectMapper: ObjectMapper
) {

    data class NotificationInboxResponse(
        val items: List<NotificationItem>,
        val nextCursor: String?,
        val limit: Int
    )

    data class NotificationItem(
        val id: UUID,
        val type: String,
        val title: String,
        val body: String?,
        val data: Map<String, Any?>,
        val read: Boolean,
        val createdAt: Instant
    )

    data class RegisterPushTokenResult(
        val platform: String,
        val token: String,
        val appVersion: String?,
        val deviceId: String,
        val updatedAt: Instant
    )

    fun getNotifications(userId: UUID, cursor: String?, limit: Int): NotificationInboxResponse {
        val normalizedLimit = limit.coerceIn(1, MAX_PAGE_SIZE)
        val decodedCursor = cursor?.let { decodeCursor(it) }
        val rows = notificationContractsRepository.findNotifications(
            userId = userId,
            cursorCreatedAt = decodedCursor?.createdAt,
            cursorId = decodedCursor?.id,
            limit = normalizedLimit + 1
        )

        val page = rows.take(normalizedLimit)
        val nextCursor = if (rows.size > normalizedLimit && page.isNotEmpty()) {
            encodeCursor(page.last().createdAt, page.last().id)
        } else {
            null
        }

        return NotificationInboxResponse(
            items = page.map {
                NotificationItem(
                    id = it.id,
                    type = it.type,
                    title = it.title,
                    body = it.body,
                    data = parseData(it.dataJson),
                    read = it.read,
                    createdAt = it.createdAt
                )
            },
            nextCursor = nextCursor,
            limit = normalizedLimit
        )
    }

    @Transactional
    fun registerPushToken(
        userId: UUID,
        platform: String,
        token: String,
        appVersion: String?,
        deviceId: String
    ): RegisterPushTokenResult {
        val normalizedPlatform = normalizePlatform(platform)
        val now = Instant.now()
        val existing = notificationContractsRepository.findDevicePushToken(userId, deviceId)

        if (existing == null) {
            notificationContractsRepository.insertDevicePushToken(
                id = UUID.randomUUID(),
                userId = userId,
                deviceId = deviceId,
                platform = normalizedPlatform,
                token = token,
                appVersion = appVersion,
                createdAt = now,
                updatedAt = now
            )
        } else {
            notificationContractsRepository.updateDevicePushToken(
                userId = userId,
                deviceId = deviceId,
                platform = normalizedPlatform,
                token = token,
                appVersion = appVersion,
                updatedAt = now
            )
        }

        return RegisterPushTokenResult(
            platform = normalizedPlatform,
            token = token,
            appVersion = appVersion,
            deviceId = deviceId,
            updatedAt = now
        )
    }

    private fun parseData(dataJson: String): Map<String, Any?> {
        if (dataJson.isBlank()) {
            return emptyMap()
        }
        return objectMapper.readValue(dataJson, object : TypeReference<Map<String, Any?>>() {})
    }

    private fun normalizePlatform(platform: String): String {
        return when (platform.trim().uppercase()) {
            "IOS" -> "IOS"
            "ANDROID" -> "ANDROID"
            else -> throw IllegalArgumentException("Unsupported platform: $platform")
        }
    }

    private fun decodeCursor(cursor: String): NotificationCursor {
        return try {
            val decoded = String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8)
            val parts = decoded.split("|", limit = 2)
            NotificationCursor(
                createdAt = Instant.parse(parts[0]),
                id = UUID.fromString(parts[1])
            )
        } catch (exception: Exception) {
            throw IllegalArgumentException("Invalid cursor")
        }
    }

    private fun encodeCursor(createdAt: Instant, id: UUID): String {
        val raw = "${createdAt}|${id}"
        return Base64.getUrlEncoder()
            .withoutPadding()
            .encodeToString(raw.toByteArray(StandardCharsets.UTF_8))
    }

    private data class NotificationCursor(
        val createdAt: Instant,
        val id: UUID
    )

    companion object {
        private const val MAX_PAGE_SIZE = 50
    }
}
