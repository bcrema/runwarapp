package com.runwar.notification

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.UUID

class NotificationContractsServiceTest {

    private val notificationContractsRepository = mockk<NotificationContractsRepository>()
    private val service = NotificationContractsService(notificationContractsRepository, jacksonObjectMapper())

    @Test
    fun `get notifications parses payload and returns next cursor`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every { notificationContractsRepository.findNotifications(userId, null, null, 3) } returns listOf(
            NotificationContractsRepository.NotificationRow(
                id = UUID.fromString("22222222-2222-2222-2222-222222222222"),
                type = "mission_progress",
                title = "Missao atualizada",
                body = "Voce correu hoje",
                dataJson = """{"missionType":"distance"}""",
                read = false,
                createdAt = Instant.parse("2026-03-16T12:00:00Z")
            ),
            NotificationContractsRepository.NotificationRow(
                id = UUID.fromString("33333333-3333-3333-3333-333333333333"),
                type = "badge_earned",
                title = "Badge liberada",
                body = null,
                dataJson = """{"slug":"marathon"}""",
                read = true,
                createdAt = Instant.parse("2026-03-16T11:00:00Z")
            ),
            NotificationContractsRepository.NotificationRow(
                id = UUID.fromString("44444444-4444-4444-4444-444444444444"),
                type = "team_presence",
                title = "Sua equipe correu",
                body = null,
                dataJson = "{}",
                read = false,
                createdAt = Instant.parse("2026-03-16T10:00:00Z")
            )
        )

        val response = service.getNotifications(userId, null, 2)

        assertEquals(2, response.items.size)
        assertEquals("distance", response.items.first().data["missionType"])
        assertNotNull(response.nextCursor)
    }

    @Test
    fun `register push token updates existing device registration`() {
        val userId = UUID.fromString("11111111-1111-1111-1111-111111111111")
        every {
            notificationContractsRepository.upsertDevicePushToken(
                id = any(),
                userId = userId,
                deviceId = "device-1",
                platform = "IOS",
                token = "new-token",
                appVersion = "1.0.0",
                createdAt = any(),
                updatedAt = any()
            )
        } returns Unit

        val result = service.registerPushToken(userId, "ios", "new-token", "1.0.0", "device-1")

        assertEquals("IOS", result.platform)
        assertEquals("device-1", result.deviceId)
        verify(exactly = 1) {
            notificationContractsRepository.upsertDevicePushToken(
                id = any(),
                userId = userId,
                deviceId = "device-1",
                platform = "IOS",
                token = "new-token",
                appVersion = "1.0.0",
                createdAt = any(),
                updatedAt = any()
            )
        }
    }
}
