package com.runwar.domain.bandeira

import com.runwar.config.UserPrincipal
import com.runwar.domain.user.UserRole
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import java.util.*

@RestController
@RequestMapping("/api/bandeiras")
class BandeiraController(private val bandeiraService: BandeiraService) {
    
    @GetMapping
    fun listAll(): ResponseEntity<List<BandeiraService.BandeiraDto>> {
        return ResponseEntity.ok(bandeiraService.findAll())
    }
    
    @GetMapping("/rankings")
    fun getRankings(): ResponseEntity<List<BandeiraService.BandeiraDto>> {
        return ResponseEntity.ok(bandeiraService.getRankings())
    }
    
    @GetMapping("/search")
    fun search(@RequestParam q: String): ResponseEntity<List<BandeiraService.BandeiraDto>> {
        return ResponseEntity.ok(bandeiraService.search(q))
    }
    
    @GetMapping("/{id}")
    fun getById(@PathVariable id: UUID): ResponseEntity<BandeiraService.BandeiraDto> {
        val bandeira = bandeiraService.findById(id)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(bandeira)
    }
    
    @GetMapping("/{id}/members")
    fun getMembers(@PathVariable id: UUID): ResponseEntity<List<BandeiraService.BandeiraMemberDto>> {
        return ResponseEntity.ok(bandeiraService.getMembers(id))
    }
    
    data class CreateBandeiraRequest(
        @field:NotBlank
        @field:Size(min = 3, max = 50)
        val name: String,
        
        @field:NotBlank
        val category: String,
        
        @field:NotBlank
        @field:Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "Must be a valid hex color")
        val color: String,
        
        @field:Size(max = 500)
        val description: String? = null
    )
    
    @PostMapping
    fun create(
        @AuthenticationPrincipal principal: UserPrincipal,
        @Valid @RequestBody request: CreateBandeiraRequest
    ): ResponseEntity<BandeiraService.BandeiraDto> {
        val category = try {
            BandeiraCategory.valueOf(request.category.uppercase())
        } catch (e: Exception) {
            return ResponseEntity.badRequest().build()
        }
        
        val bandeira = bandeiraService.create(
            user = principal.user,
            name = request.name,
            category = category,
            color = request.color,
            description = request.description
        )
        
        return ResponseEntity.ok(bandeira)
    }
    
    @PostMapping("/{id}/join")
    fun join(
        @AuthenticationPrincipal principal: UserPrincipal,
        @PathVariable id: UUID
    ): ResponseEntity<BandeiraService.BandeiraDto> {
        val bandeira = bandeiraService.join(principal.user, id)
        return ResponseEntity.ok(bandeira)
    }
    
    @PostMapping("/leave")
    fun leave(@AuthenticationPrincipal principal: UserPrincipal): ResponseEntity<Map<String, Boolean>> {
        bandeiraService.leave(principal.user)
        return ResponseEntity.ok(mapOf("success" to true))
    }
    
    data class UpdateRoleRequest(
        val userId: UUID,
        val role: String
    )
    
    @PutMapping("/{id}/members/role")
    fun updateMemberRole(
        @AuthenticationPrincipal principal: UserPrincipal,
        @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateRoleRequest
    ): ResponseEntity<Map<String, Boolean>> {
        val role = try {
            UserRole.valueOf(request.role.uppercase())
        } catch (e: Exception) {
            return ResponseEntity.badRequest().build()
        }
        
        bandeiraService.updateMemberRole(principal.user, request.userId, role)
        return ResponseEntity.ok(mapOf("success" to true))
    }
}
