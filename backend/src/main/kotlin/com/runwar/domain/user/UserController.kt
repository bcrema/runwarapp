package com.runwar.domain.user

import jakarta.validation.Valid
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size
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

    class UpdateMeRequest(
        @field:Size(min = 3, max = 30)
        val username: String? = null,
        @field:JsonProperty("profile_visibility")
        @field:Pattern(
            regexp = "^(public|private)$",
            message = "profile_visibility must be public or private"
        )
        val profileVisibility: String? = null
    ) {
        @JsonIgnore
        private val unknownFields: MutableSet<String> = mutableSetOf()

        @JsonAnySetter
        fun setUnknownField(key: String, value: Any?) {
            unknownFields.add(key)
        }

        @AssertTrue(message = "Only username and profile_visibility can be updated")
        fun isHasOnlyKnownFields(): Boolean = unknownFields.isEmpty()
    }

    @PatchMapping("/me", "/users/me")
    fun updateMe(
        @AuthenticationPrincipal principal: UserPrincipal,
        @Valid @RequestBody request: UpdateMeRequest
    ): ResponseEntity<MeResponse> {
        val updated = userService.updateMe(
            principal.user.id,
            request.username,
            request.profileVisibility
        )
        return ResponseEntity.ok(
            MeResponse(
                id = updated.id,
                username = updated.username,
                email = updated.email,
                profileVisibility = updated.profileVisibility
            )
        )
    }
}
