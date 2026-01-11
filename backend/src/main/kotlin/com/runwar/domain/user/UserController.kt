package com.runwar.domain.user

import jakarta.validation.Valid
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import com.runwar.config.UserPrincipal

@RestController
@RequestMapping("/api")
class UserController(private val userService: UserService) {
    
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
        val token: String
    )
    
    @PostMapping("/auth/register")
    fun register(@Valid @RequestBody request: RegisterRequest): ResponseEntity<AuthResponse> {
        val result = userService.register(request.email, request.username, request.password)
        return ResponseEntity.ok(AuthResponse(result.user, result.token))
    }
    
    @PostMapping("/auth/login")
    fun login(@Valid @RequestBody request: LoginRequest): ResponseEntity<AuthResponse> {
        val result = userService.login(request.email, request.password)
        return ResponseEntity.ok(AuthResponse(result.user, result.token))
    }
    
    // ===== User Endpoints (Authenticated) =====
    
    @GetMapping("/users/me")
    fun getCurrentUser(@AuthenticationPrincipal principal: UserPrincipal): ResponseEntity<UserService.UserDto> {
        val profile = userService.getProfile(principal.user.id)
        return ResponseEntity.ok(profile)
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
}
