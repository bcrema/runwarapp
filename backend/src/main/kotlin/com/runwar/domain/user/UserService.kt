package com.runwar.domain.user

import com.runwar.config.JwtService
import com.runwar.config.JwtProperties
import com.runwar.config.UnauthorizedException
import com.runwar.config.UserPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.MessageDigest
import java.security.SecureRandom
import java.time.Instant
import java.util.Base64
import java.util.*

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtService: JwtService,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val jwtProperties: JwtProperties
) : UserDetailsService {

    data class MeDto(
        val id: UUID,
        val username: String,
        val email: String,
        val profileVisibility: String
    )
    
    data class AuthResult(
        val user: UserDto,
        val accessToken: String,
        val refreshToken: String
    )
    
    data class UserDto(
        val id: UUID,
        val email: String,
        val username: String,
        val avatarUrl: String?,
        val isPublic: Boolean,
        val bandeiraId: UUID?,
        val bandeiraName: String?,
        val role: String,
        val totalRuns: Int,
        val totalDistance: Double, // kilometers (iOS compatibility)
        val totalDistanceMeters: Double,
        val totalQuadrasConquered: Int
    ) {
        companion object {
            fun from(user: User): UserDto {
                val totalDistanceMeters = user.totalDistance.toDouble()
                return UserDto(
                id = user.id,
                email = user.email,
                username = user.username,
                avatarUrl = user.avatarUrl,
                isPublic = user.isPublic,
                bandeiraId = user.bandeira?.id,
                bandeiraName = user.bandeira?.name,
                role = user.role.name,
                totalRuns = user.totalRuns,
                totalDistance = totalDistanceMeters / 1000.0,
                totalDistanceMeters = totalDistanceMeters,
                totalQuadrasConquered = user.totalQuadrasConquered
            )
            }
        }
    }
    
    override fun loadUserByUsername(email: String): UserDetails {
        val user = userRepository.findByEmail(email)
            ?: throw UsernameNotFoundException("User not found with email: $email")
        return UserPrincipal(user)
    }
    
    @Transactional
    fun register(email: String, username: String, password: String): AuthResult {
        if (userRepository.existsByEmail(email)) {
            throw IllegalArgumentException("Email already registered")
        }
        if (userRepository.existsByUsername(username)) {
            throw IllegalArgumentException("Username already taken")
        }
        
        val user = User(
            email = email,
            username = username,
            passwordHash = passwordEncoder.encode(password)
        )
        
        val savedUser = userRepository.save(user)
        val tokens = issueTokens(savedUser)
        
        return AuthResult(UserDto.from(savedUser), tokens.accessToken, tokens.refreshToken)
    }
    
    fun login(email: String, password: String): AuthResult {
        val user = userRepository.findWithBandeiraByEmail(email)
            ?: throw IllegalArgumentException("Invalid credentials")
        
        if (!passwordEncoder.matches(password, user.passwordHash)) {
            throw IllegalArgumentException("Invalid credentials")
        }
        
        val tokens = issueTokens(user)
        
        return AuthResult(UserDto.from(user), tokens.accessToken, tokens.refreshToken)
    }

    private fun validateRefreshTokenFormat(refreshToken: String) {
        // Expect a Base64 URL-encoded string (~86 chars for 64 random bytes)
        if (refreshToken.length !in 80..100) {
            throw UnauthorizedException("Invalid refresh token")
        }
        if (!refreshToken.matches(Regex("^[A-Za-z0-9_-]+$"))) {
            throw UnauthorizedException("Invalid refresh token")
        }
    }

    @Transactional
    fun refresh(refreshToken: String): AuthResult {
        validateRefreshTokenFormat(refreshToken)
        val tokenHash = hashToken(refreshToken)
        val storedToken = refreshTokenRepository.findByTokenHash(tokenHash)
            ?: throw UnauthorizedException("Invalid refresh token")

        val now = Instant.now()
        if (storedToken.revokedAt != null || !storedToken.expiresAt.isAfter(now)) {
            throw UnauthorizedException("Refresh token expired or revoked")
        }

        val user = storedToken.user
        val newRefreshToken = generateRefreshToken()
        val newRefreshHash = hashToken(newRefreshToken)

        storedToken.revokedAt = now
        storedToken.replacedByTokenHash = newRefreshHash
        refreshTokenRepository.save(storedToken)

        val newTokenRecord = RefreshToken(
            user = user,
            tokenHash = newRefreshHash,
            expiresAt = now.plusMillis(jwtProperties.refreshExpiration)
        )
        refreshTokenRepository.save(newTokenRecord)

        val accessToken = jwtService.generateToken(user.id, user.email)
        return AuthResult(UserDto.from(user), accessToken, newRefreshToken)
    }

    @Transactional
    fun logout(refreshToken: String) {
        val tokenHash = hashToken(refreshToken)
        val storedToken = refreshTokenRepository.findByTokenHash(tokenHash) ?: return
        if (storedToken.revokedAt == null) {
            storedToken.revokedAt = Instant.now()
            refreshTokenRepository.save(storedToken)
        }
    }
    
    fun findById(id: UUID): User? = userRepository.findByIdWithBandeira(id)
    
    fun getProfile(userId: UUID): UserDto {
        val user = findUser(userId)
        return UserDto.from(user)
    }

    fun getMe(userId: UUID): MeDto {
        val user = findUser(userId)
        return toMeDto(user)
    }
    
    @Transactional
    fun updateProfile(userId: UUID, username: String?, avatarUrl: String?, isPublic: Boolean?): UserDto {
        val user = findUser(userId)

        applyUsernameUpdate(user, username)
        
        avatarUrl?.let { user.avatarUrl = it }
        isPublic?.let { user.isPublic = it }

        return UserDto.from(userRepository.save(user))
    }

    @Transactional
    fun updateMe(userId: UUID, username: String?, profileVisibility: String?): MeDto {
        val user = findUser(userId)

        applyUsernameUpdate(user, username)

        profileVisibility?.let { user.isPublic = toIsPublic(it) }

        val savedUser = userRepository.save(user)
        return toMeDto(savedUser)
    }

    private fun toMeDto(user: User): MeDto {
        return MeDto(
            id = user.id,
            username = user.username,
            email = user.email,
            profileVisibility = toProfileVisibility(user.isPublic)
        )
    }

    private fun toProfileVisibility(isPublic: Boolean): String = if (isPublic) "public" else "private"

    private fun toIsPublic(profileVisibility: String): Boolean = when (profileVisibility) {
        "public" -> true
        "private" -> false
        else -> throw IllegalArgumentException("Invalid profile_visibility")
    }

    private fun findUser(userId: UUID): User {
        return userRepository.findByIdWithBandeira(userId)
            ?: throw IllegalArgumentException("User not found")
    }

    private fun applyUsernameUpdate(user: User, username: String?) {
        username?.let {
            if (it != user.username && userRepository.existsByUsername(it)) {
                throw IllegalArgumentException("This username is already taken by another user")
            }
            user.username = it
        }
    }

    private data class TokenPair(
        val accessToken: String,
        val refreshToken: String
    )

    private fun issueTokens(user: User): TokenPair {
        val accessToken = jwtService.generateToken(user.id, user.email)
        val refreshToken = generateRefreshToken()
        val refreshTokenHash = hashToken(refreshToken)
        val tokenRecord = RefreshToken(
            user = user,
            tokenHash = refreshTokenHash,
            expiresAt = Instant.now().plusMillis(jwtProperties.refreshExpiration)
        )
        refreshTokenRepository.save(tokenRecord)
        return TokenPair(accessToken, refreshToken)
    }

    private fun generateRefreshToken(): String {
        val randomBytes = ByteArray(64)
        secureRandom.nextBytes(randomBytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes)
    }

    private fun hashToken(token: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashed = digest.digest(token.toByteArray(Charsets.UTF_8))
        return hashed.joinToString("") { "%02x".format(it) }
    }

    companion object {
        private val secureRandom = SecureRandom()
    }
}
