package com.runwar.domain.user

import com.runwar.config.JwtService
import com.runwar.config.UserPrincipal
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtService: JwtService
) : UserDetailsService {
    
    data class AuthResult(
        val user: UserDto,
        val token: String
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
        val totalDistance: Double,
        val totalTilesConquered: Int
    ) {
        companion object {
            fun from(user: User) = UserDto(
                id = user.id,
                email = user.email,
                username = user.username,
                avatarUrl = user.avatarUrl,
                isPublic = user.isPublic,
                bandeiraId = user.bandeira?.id,
                bandeiraName = user.bandeira?.name,
                role = user.role.name,
                totalRuns = user.totalRuns,
                totalDistance = user.totalDistance.toDouble(),
                totalTilesConquered = user.totalTilesConquered
            )
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
        val token = jwtService.generateToken(savedUser.id, savedUser.email)
        
        return AuthResult(UserDto.from(savedUser), token)
    }
    
    fun login(email: String, password: String): AuthResult {
        val user = userRepository.findByEmail(email)
            ?: throw IllegalArgumentException("Invalid credentials")
        
        if (!passwordEncoder.matches(password, user.passwordHash)) {
            throw IllegalArgumentException("Invalid credentials")
        }
        
        val token = jwtService.generateToken(user.id, user.email)
        
        return AuthResult(UserDto.from(user), token)
    }
    
    fun findById(id: UUID): User? = userRepository.findById(id).orElse(null)
    
    fun getProfile(userId: UUID): UserDto {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        return UserDto.from(user)
    }
    
    @Transactional
    fun updateProfile(userId: UUID, username: String?, avatarUrl: String?, isPublic: Boolean?): UserDto {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        username?.let {
            if (it != user.username && userRepository.existsByUsername(it)) {
                throw IllegalArgumentException("Username already taken")
            }
            user.username = it
        }
        
        avatarUrl?.let { user.avatarUrl = it }
        isPublic?.let { user.isPublic = it }
        
        return UserDto.from(userRepository.save(user))
    }
}
