package com.runwar.domain.user

import jakarta.validation.Valid
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import jakarta.servlet.http.HttpServletRequest
import java.util.UUID
import org.springframework.http.ResponseEntity
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import com.runwar.config.SocialLinkRequiredException
import com.runwar.config.UnauthorizedException
import com.runwar.config.UserPrincipal

@RestController
@RequestMapping("/api")
class UserController(
    private val userService: UserService,
    private val socialAuthService: SocialAuthService,
    private val authRateLimiter: AuthRateLimiter,
    private val userContractsService: UserContractsService
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

    data class SocialExchangeRequest(
        @field:NotBlank
        val provider: String,

        @field:NotBlank
        val idToken: String,

        val authorizationCode: String? = null,
        val nonce: String? = null,

        @field:Email
        val emailHint: String? = null,

        val givenName: String? = null,
        val familyName: String? = null,
        val avatarUrl: String? = null
    )

    data class SocialLinkConfirmRequest(
        @field:NotBlank
        val linkToken: String,

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
        val ip = resolveClientIp(httpRequest)
        val ipKey = "login:ip:$ip"
        val emailKey = "login:email:${request.email.lowercase()}"

        authRateLimiter.ensureAllowed(ipKey)
        authRateLimiter.ensureAllowed(emailKey)

        val result = try {
            userService.login(request.email, request.password)
        } catch (e: IllegalArgumentException) {
            authRateLimiter.recordFailure(ipKey)
            authRateLimiter.recordFailure(emailKey)
            throw BadCredentialsException("Invalid credentials")
        }

        authRateLimiter.reset(ipKey)
        authRateLimiter.reset(emailKey)

        return ResponseEntity.ok(
            AuthResponse(
                user = toUserResponse(result.user),
                accessToken = result.accessToken,
                refreshToken = result.refreshToken
            )
        )
    }

    @PostMapping("/auth/social/exchange")
    fun socialExchange(
        @Valid @RequestBody request: SocialExchangeRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<AuthResponse> {
        val ip = resolveClientIp(httpRequest)
        val ipKey = "social-exchange:ip:$ip"

        authRateLimiter.ensureAllowed(ipKey)

        val result = try {
            socialAuthService.exchange(
                SocialAuthService.SocialExchangePayload(
                    provider = request.provider,
                    idToken = request.idToken,
                    authorizationCode = request.authorizationCode,
                    nonce = request.nonce,
                    emailHint = request.emailHint,
                    givenName = request.givenName,
                    familyName = request.familyName,
                    avatarUrl = request.avatarUrl
                )
            )
        } catch (e: SocialLinkRequiredException) {
            authRateLimiter.reset(ipKey)
            throw e
        } catch (e: UnauthorizedException) {
            authRateLimiter.recordFailure(ipKey)
            throw e
        }

        authRateLimiter.reset(ipKey)
        return ResponseEntity.ok(
            AuthResponse(
                user = toUserResponse(result.user),
                accessToken = result.accessToken,
                refreshToken = result.refreshToken
            )
        )
    }

    @PostMapping("/auth/social/link/confirm")
    fun confirmSocialLink(
        @Valid @RequestBody request: SocialLinkConfirmRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<AuthResponse> {
        val ip = resolveClientIp(httpRequest)
        val ipKey = "social-link:ip:$ip"
        val emailKey = "social-link:email:${request.email.trim().lowercase()}"

        authRateLimiter.ensureAllowed(ipKey)
        authRateLimiter.ensureAllowed(emailKey)

        val result = try {
            socialAuthService.confirmLink(request.linkToken, request.email, request.password)
        } catch (e: UnauthorizedException) {
            authRateLimiter.recordFailure(ipKey)
            authRateLimiter.recordFailure(emailKey)
            throw BadCredentialsException("Invalid credentials")
        }

        authRateLimiter.reset(ipKey)
        authRateLimiter.reset(emailKey)
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

    @GetMapping("/users/rankings")
    fun getUserRankings(
        @AuthenticationPrincipal principal: UserPrincipal,
        @RequestParam(defaultValue = "season") scope: String
    ): ResponseEntity<UserContractsService.UserRankingResponse> {
        return ResponseEntity.ok(userContractsService.getUserRankings(principal.user.id, scope))
    }

    @GetMapping("/users/me/badges")
    fun getMyBadges(
        @AuthenticationPrincipal principal: UserPrincipal
    ): ResponseEntity<List<UserContractsService.BadgeResponse>> {
        return ResponseEntity.ok(userContractsService.getMyBadges(principal.user.id))
    }

    @GetMapping("/users/me/missions/active")
    fun getActiveMissions(
        @AuthenticationPrincipal principal: UserPrincipal
    ): ResponseEntity<List<UserContractsService.ActiveMissionResponse>> {
        return ResponseEntity.ok(userContractsService.getActiveMissions(principal.user.id))
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
