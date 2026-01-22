package com.runwar.domain.user

import jakarta.validation.Valid
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import com.runwar.config.UserPrincipal
import com.fasterxml.jackson.annotation.JsonAnySetter
import com.fasterxml.jackson.annotation.JsonIgnore
import com.fasterxml.jackson.annotation.JsonProperty
import jakarta.validation.constraints.AssertTrue

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
    
    data class AuthResponse(
        val user: UserService.UserDto,
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
        return ResponseEntity.ok(AuthResponse(result.user, result.accessToken, result.refreshToken))
    }
    
    @PostMapping("/auth/login")
    fun login(
        @Valid @RequestBody request: LoginRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<AuthResponse> {
        enforceRateLimit("login", request.email, httpRequest)
        val result = userService.login(request.email, request.password)
        return ResponseEntity.ok(AuthResponse(result.user, result.accessToken, result.refreshToken))
    }

    @PostMapping("/auth/refresh")
    fun refresh(@Valid @RequestBody request: RefreshRequest): ResponseEntity<AuthResponse> {
        val result = userService.refresh(request.refreshToken)
        return ResponseEntity.ok(AuthResponse(result.user, result.accessToken, result.refreshToken))
    }

    @PostMapping("/auth/logout")
    fun logout(@Valid @RequestBody request: LogoutRequest): ResponseEntity<Void> {
        userService.logout(request.refreshToken)
        return ResponseEntity.noContent().build()
    }
    
    // ===== User Endpoints (Authenticated) =====
    
    data class MeResponse(
        val id: java.util.UUID,
        val username: String,
        val email: String,
        @field:JsonProperty("profile_visibility")
        val profileVisibility: String
    )

    @GetMapping("/me", "/users/me")
    fun getMe(@AuthenticationPrincipal principal: UserPrincipal): ResponseEntity<MeResponse> {
        val profile = userService.getMe(principal.user.id)
        return ResponseEntity.ok(
            MeResponse(
                id = profile.id,
                username = profile.username,
                email = profile.email,
                profileVisibility = profile.profileVisibility
            )
        )
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
    ): ResponseEntity<UserService.UserDto> {
        val updated = userService.updateProfile(
            principal.user.id,
            request.username,
            request.avatarUrl,
            request.isPublic
        )
        return ResponseEntity.ok(updated)
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
}
