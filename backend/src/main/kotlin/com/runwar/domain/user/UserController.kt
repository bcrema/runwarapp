package com.runwar.domain.user

import jakarta.validation.Valid
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import jakarta.servlet.http.HttpServletRequest
import java.util.UUID
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import com.runwar.config.UserPrincipal

@RestController
@RequestMapping("/api")
class UserController(
    private val userService: UserService,
    private val authRateLimiter: AuthRateLimiter
) {
    
    // ===== Auth Endpoints (Public) =====
    
    data class RegisterRequest(
        @field:Email
        @field:NotBlank
        val email: String,
        
        @field:NotBlank
        @field:Size(min = 3, max = 30)
        val username: String,
        
        @field:NotBlank
        @field:Size(min = 6)
        val password: String
    )
    
    data class LoginRequest(
        @field:Email
        @field:NotBlank
        val email: String,
        
        @field:NotBlank
        val password: String
    )
    
    data class UserResponse(
        val id: UUID,
        val email: String,
        val username: String,
        val avatarUrl: String?,
        val isPublic: Boolean,
        val bandeiraId: UUID?,
        val bandeiraName: String?,
        val role: String,
        val totalRuns: Int,
        val totalDistance: Double,
        val totalDistanceMeters: Double,
        val totalQuadrasConquered: Int
    )

    data class AuthResponse(
        val user: UserResponse,
        val accessToken: String,
        val refreshToken: String
    )

    data class RefreshRequest(
        @field:NotBlank
        val refreshToken: String
    )

    data class LogoutRequest(
        @field:NotBlank
        val refreshToken: String
    )
    
    @PostMapping("/auth/signup", "/auth/register")
    fun signup(
        @Valid @RequestBody request: RegisterRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<AuthResponse> {
        enforceRateLimit("signup", request.email, httpRequest)
        val result = userService.register(request.email, request.username, request.password)
        return ResponseEntity.ok(
            AuthResponse(
                user = toUserResponse(result.user),
                accessToken = result.accessToken,
                refreshToken = result.refreshToken
            )
        )
    }
    
    @PostMapping("/auth/login")
    fun login(
        @Valid @RequestBody request: LoginRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<AuthResponse> {
        enforceRateLimit("login", request.email, httpRequest)
        val result = userService.login(request.email, request.password)
        return ResponseEntity.ok(
            AuthResponse(
                user = toUserResponse(result.user),
                accessToken = result.accessToken,
                refreshToken = result.refreshToken
            )
        )
    }

    @PostMapping("/auth/refresh")
    fun refresh(@Valid @RequestBody request: RefreshRequest): ResponseEntity<AuthResponse> {
        val result = userService.refresh(request.refreshToken)
        return ResponseEntity.ok(
            AuthResponse(
                user = toUserResponse(result.user),
                accessToken = result.accessToken,
                refreshToken = result.refreshToken
            )
        )
    }

    @PostMapping("/auth/logout")
    fun logout(@Valid @RequestBody request: LogoutRequest): ResponseEntity<Void> {
        userService.logout(request.refreshToken)
        return ResponseEntity.noContent().build()
    }
    
    // ===== User Endpoints (Authenticated) =====

    @GetMapping("/me", "/users/me")
    fun getMe(@AuthenticationPrincipal principal: UserPrincipal): ResponseEntity<UserResponse> {
        val profile = userService.getProfile(principal.user.id)
        return ResponseEntity.ok(toUserResponse(profile))
    }
    
    data class UpdateProfileRequest(
        @field:Size(min = 3, max = 30)
        val username: String? = null,
        val avatarUrl: String? = null,
        val isPublic: Boolean? = null
    )
    
    @PutMapping("/users/me")
    fun updateProfile(
        @AuthenticationPrincipal principal: UserPrincipal,
        @Valid @RequestBody request: UpdateProfileRequest
    ): ResponseEntity<UserResponse> {
        val updated = userService.updateProfile(
            principal.user.id,
            request.username,
            request.avatarUrl,
            request.isPublic
        )
        return ResponseEntity.ok(toUserResponse(updated))
    }

    private fun enforceRateLimit(action: String, email: String, request: HttpServletRequest) {
        val ip = resolveClientIp(request)
        authRateLimiter.check("$action:ip:$ip")
        authRateLimiter.check("$action:email:${email.lowercase()}")
    }

    private fun resolveClientIp(request: HttpServletRequest): String {
        val forwarded = request.getHeader("X-Forwarded-For")
        return forwarded?.split(",")?.firstOrNull()?.trim()?.takeIf { it.isNotBlank() }
            ?: request.remoteAddr
            ?: "unknown"
    }

    private fun toUserResponse(user: UserService.UserDto): UserResponse {
        return UserResponse(
            id = user.id,
            email = user.email,
            username = user.username,
            avatarUrl = user.avatarUrl,
            isPublic = user.isPublic,
            bandeiraId = user.bandeiraId,
            bandeiraName = user.bandeiraName,
            role = user.role,
            totalRuns = user.totalRuns,
            totalDistance = user.totalDistance,
            totalDistanceMeters = user.totalDistanceMeters,
            totalQuadrasConquered = user.totalQuadrasConquered
        )
    }
}
