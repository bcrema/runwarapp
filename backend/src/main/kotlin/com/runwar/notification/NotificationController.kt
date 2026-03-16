package com.runwar.notification

import com.runwar.config.UserPrincipal
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
class NotificationController(
    private val notificationContractsService: NotificationContractsService
) {

    data class RegisterPushTokenRequest(
        @field:NotBlank
        val platform: String,
        @field:NotBlank
        @field:Size(max = 512)
        val token: String,
        @field:Size(max = 100)
        val appVersion: String? = null,
        @field:NotBlank
        @field:Size(max = 255)
        val deviceId: String
    )

    @GetMapping("/notifications")
    fun getNotifications(
        @AuthenticationPrincipal principal: UserPrincipal,
        @RequestParam(required = false) cursor: String?,
        @RequestParam(defaultValue = "20") limit: Int
    ): ResponseEntity<NotificationContractsService.NotificationInboxResponse> {
        return ResponseEntity.ok(
            notificationContractsService.getNotifications(principal.user.id, cursor, limit)
        )
    }

    @PostMapping("/devices/push-token")
    fun registerPushToken(
        @AuthenticationPrincipal principal: UserPrincipal,
        @Valid @RequestBody request: RegisterPushTokenRequest
    ): ResponseEntity<NotificationContractsService.RegisterPushTokenResult> {
        return ResponseEntity.ok(
            notificationContractsService.registerPushToken(
                userId = principal.user.id,
                platform = request.platform,
                token = request.token,
                appVersion = request.appVersion,
                deviceId = request.deviceId
            )
        )
    }
}
