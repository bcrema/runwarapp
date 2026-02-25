package com.runwar.domain.bandeira

import com.runwar.domain.user.User
import com.runwar.domain.user.UserRepository
import com.runwar.domain.user.UserRole
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

@Service
@Transactional(readOnly = true)
class BandeiraService(
    private val bandeiraRepository: BandeiraRepository,
    private val userRepository: UserRepository
) {
    
    data class BandeiraDto(
        val id: UUID,
        val name: String,
        val slug: String,
        val category: String,
        val color: String,
        val logoUrl: String?,
        val description: String?,
        val memberCount: Int,
        val totalQuadras: Int,
        val createdById: UUID,
        val createdByUsername: String
    ) {
        companion object {
            fun from(bandeira: Bandeira) = BandeiraDto(
                id = bandeira.id,
                name = bandeira.name,
                slug = bandeira.slug,
                category = bandeira.category.name,
                color = bandeira.color,
                logoUrl = bandeira.logoUrl,
                description = bandeira.description,
                memberCount = bandeira.memberCount,
                totalQuadras = bandeira.totalQuadras,
                createdById = bandeira.createdBy.id,
                createdByUsername = bandeira.createdBy.username
            )
        }
    }
    
    data class BandeiraMemberDto(
        val id: UUID,
        val username: String,
        val avatarUrl: String?,
        val role: String,
        val totalQuadrasConquered: Int
    )
    
    fun findAll(): List<BandeiraDto> {
        return bandeiraRepository.findAll().map { BandeiraDto.from(it) }
    }
    
    fun findById(id: UUID): BandeiraDto? {
        return bandeiraRepository.findById(id).map { BandeiraDto.from(it) }.orElse(null)
    }
    
    fun findBySlug(slug: String): BandeiraDto? {
        return bandeiraRepository.findBySlug(slug)?.let { BandeiraDto.from(it) }
    }
    
    fun getMembers(bandeiraId: UUID): List<BandeiraMemberDto> {
        return userRepository.findByBandeiraId(bandeiraId).map {
            BandeiraMemberDto(
                id = it.id,
                username = it.username,
                avatarUrl = it.avatarUrl,
                role = it.role.name,
                totalQuadrasConquered = it.totalQuadrasConquered
            )
        }
    }
    
    @Transactional
    fun create(
        user: User,
        name: String,
        category: BandeiraCategory,
        color: String,
        description: String?
    ): BandeiraDto {
        if (user.bandeira != null) {
            throw IllegalArgumentException("User already belongs to a bandeira")
        }
        
        val slug = generateSlug(name)
        if (bandeiraRepository.existsBySlug(slug)) {
            throw IllegalArgumentException("A bandeira with similar name already exists")
        }
        
        val bandeira = Bandeira(
            name = name,
            slug = slug,
            category = category,
            color = color,
            description = description,
            createdBy = user
        )
        
        val saved = bandeiraRepository.save(bandeira)
        
        // Make creator an admin and assign to bandeira
        user.bandeira = saved
        user.role = UserRole.ADMIN
        userRepository.save(user)
        
        return BandeiraDto.from(saved)
    }
    
    @Transactional
    fun join(user: User, bandeiraId: UUID): BandeiraDto {
        if (user.bandeira != null) {
            throw IllegalArgumentException("User already belongs to a bandeira. Leave first.")
        }
        
        val bandeira = bandeiraRepository.findById(bandeiraId)
            .orElseThrow { IllegalArgumentException("Bandeira not found") }
        
        user.bandeira = bandeira
        user.role = UserRole.MEMBER
        userRepository.save(user)
        
        bandeira.memberCount++
        bandeiraRepository.save(bandeira)
        
        return BandeiraDto.from(bandeira)
    }
    
    @Transactional
    fun leave(user: User): Boolean {
        val bandeira = user.bandeira
            ?: throw IllegalArgumentException("User does not belong to any bandeira")
        
        // Can't leave if you're the only admin
        if (user.role == UserRole.ADMIN) {
            val admins = userRepository.findByBandeiraId(bandeira.id)
                .filter { it.role == UserRole.ADMIN }
            if (admins.size <= 1) {
                throw IllegalArgumentException("Cannot leave: you are the only admin. Transfer ownership first.")
            }
        }
        
        user.bandeira = null
        user.role = UserRole.MEMBER
        userRepository.save(user)
        
        bandeira.memberCount = maxOf(0, bandeira.memberCount - 1)
        bandeiraRepository.save(bandeira)
        
        return true
    }
    
    @Transactional
    fun updateMemberRole(adminUser: User, targetUserId: UUID, newRole: UserRole): Boolean {
        if (adminUser.role != UserRole.ADMIN) {
            throw IllegalArgumentException("Only admins can change roles")
        }
        
        val targetUser = userRepository.findById(targetUserId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        if (targetUser.bandeira?.id != adminUser.bandeira?.id) {
            throw IllegalArgumentException("User is not in your bandeira")
        }
        
        targetUser.role = newRole
        userRepository.save(targetUser)
        
        return true
    }
    
    fun getRankings(): List<BandeiraDto> {
        return bandeiraRepository.findAllOrderByTotalQuadrasDesc().map { BandeiraDto.from(it) }
    }
    
    fun search(query: String): List<BandeiraDto> {
        return bandeiraRepository.findByNameContainingIgnoreCase(query).map { BandeiraDto.from(it) }
    }
    
    private fun generateSlug(name: String): String {
        return name.lowercase()
            .replace(Regex("[^a-z0-9\\s-]"), "")
            .replace(Regex("\\s+"), "-")
            .take(50)
    }
}
