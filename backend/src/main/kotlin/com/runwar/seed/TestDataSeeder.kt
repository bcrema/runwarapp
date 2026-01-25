package com.runwar.seed

import com.runwar.domain.bandeira.Bandeira
import com.runwar.domain.bandeira.BandeiraCategory
import com.runwar.domain.bandeira.BandeiraRepository
import com.runwar.domain.tile.OwnerType
import com.runwar.domain.tile.Tile
import com.runwar.domain.tile.TileRepository
import com.runwar.domain.user.User
import com.runwar.domain.user.UserRepository
import com.runwar.domain.user.UserRole
import com.runwar.game.H3GridService
import java.time.Instant
import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional

@Component
@ConditionalOnProperty(name = ["runwar.seed.enabled"], havingValue = "true")
class TestDataSeeder(
    private val userRepository: UserRepository,
    private val bandeiraRepository: BandeiraRepository,
    private val tileRepository: TileRepository,
    private val passwordEncoder: PasswordEncoder,
    private val h3GridService: H3GridService
) : ApplicationRunner {
    private val log = LoggerFactory.getLogger(TestDataSeeder::class.java)

    @Transactional
    override fun run(args: ApplicationArguments) {
        val alphaAdminEmail = "alpha.admin+seed@runwar.local"
        if (userRepository.existsByEmail(alphaAdminEmail)) return
        log.info("Seeding mock data (users/bandeiras/tiles) into database...")

        val password = "password123"
        val alphaAdmin = createUser(email = alphaAdminEmail, username = "alpha_admin", password = password, role = UserRole.ADMIN)
        val betaAdmin = createUser(email = "beta.admin+seed@runwar.local", username = "beta_admin", password = password, role = UserRole.ADMIN)
        val alice = createUser(email = "alice+seed@runwar.local", username = "alice", password = password)
        val bob = createUser(email = "bob+seed@runwar.local", username = "bob", password = password)
        val carol = createUser(email = "carol+seed@runwar.local", username = "carol", password = password)
        val dave = createUser(email = "dave+seed@runwar.local", username = "dave", password = password)

        val alpha =
            bandeiraRepository.save(
                Bandeira(
                    name = "LigaRun Alpha",
                    slug = "ligarun-alpha",
                    category = BandeiraCategory.GRUPO,
                    color = "#E63946",
                    description = "Mock team for local testing",
                    createdBy = alphaAdmin
                )
            )

        val beta =
            bandeiraRepository.save(
                Bandeira(
                    name = "LigaRun Beta",
                    slug = "ligarun-beta",
                    category = BandeiraCategory.ASSESSORIA,
                    color = "#1D3557",
                    description = "Mock team for local testing",
                    createdBy = betaAdmin
                )
            )

        alphaAdmin.bandeira = alpha
        alphaAdmin.role = UserRole.ADMIN
        alice.bandeira = alpha
        bob.bandeira = alpha
        betaAdmin.bandeira = beta
        betaAdmin.role = UserRole.ADMIN
        carol.bandeira = beta

        userRepository.saveAll(listOf(alphaAdmin, betaAdmin, alice, bob, carol))

        alpha.memberCount = userRepository.findByBandeiraId(alpha.id).size
        beta.memberCount = userRepository.findByBandeiraId(beta.id).size
        bandeiraRepository.saveAll(listOf(alpha, beta))

        seedTiles(alpha, beta, alphaAdmin, dave)
        log.info("Mock data seeding completed.")
    }

    private fun seedTiles(alpha: Bandeira, beta: Bandeira, admin: User, dave: User) {
        val now = Instant.now()
        val baseTileId = h3GridService.getTileId(-25.4386, -49.2732)
        val tileIds = generateTileIds(baseTileId, count = 22)

        val tiles =
            tileIds.mapIndexed { index, tileId ->
                val ownerType: OwnerType
                val ownerId: java.util.UUID
                val shield: Int
                val guardian: User

                when {
                    index < 10 -> {
                        ownerType = OwnerType.BANDEIRA
                        ownerId = alpha.id
                        shield = 100
                        guardian = admin
                    }
                    index < 16 -> {
                        ownerType = OwnerType.BANDEIRA
                        ownerId = beta.id
                        shield = if (index % 2 == 0) 85 else 55
                        guardian = dave
                    }
                    index < 19 -> {
                        ownerType = OwnerType.SOLO
                        ownerId = admin.id
                        shield = if (index % 2 == 0) 90 else 60
                        guardian = admin
                    }
                    else -> {
                        ownerType = OwnerType.SOLO
                        ownerId = dave.id
                        shield = 75
                        guardian = dave
                    }
                }

                Tile(
                    id = tileId,
                    center = h3GridService.getTileCenterAsPoint(tileId),
                    ownerType = ownerType,
                    ownerId = ownerId,
                    shield = shield,
                    cooldownUntil = if (shield < 70) now.plusSeconds(6 * 60 * 60) else null,
                    guardian = guardian,
                    guardianContribution = 10,
                    lastActionAt = now.minusSeconds((index + 1).toLong() * 3600)
                )
            }

        tileRepository.saveAll(tiles)

        alpha.totalTiles = tileRepository.countByOwnerId(alpha.id)
        beta.totalTiles = tileRepository.countByOwnerId(beta.id)
        bandeiraRepository.saveAll(listOf(alpha, beta))

        admin.totalTilesConquered = tileRepository.countByOwnerId(admin.id)
        dave.totalTilesConquered = tileRepository.countByOwnerId(dave.id)
        userRepository.saveAll(listOf(admin, dave))
    }

    private fun createUser(email: String, username: String, password: String, role: UserRole = UserRole.MEMBER): User {
        return userRepository.save(
            User(
                email = email,
                username = username,
                passwordHash = passwordEncoder.encode(password),
                role = role,
                isPublic = true
            )
        )
    }

    private fun generateTileIds(baseTileId: String, count: Int): List<String> {
        val visited = LinkedHashSet<String>()
        val queue = ArrayDeque<String>()

        visited.add(baseTileId)
        queue.add(baseTileId)

        while (queue.isNotEmpty() && visited.size < count) {
            val current = queue.removeFirst()
            val neighbors = h3GridService.getNeighbors(current)
            for (neighbor in neighbors) {
                if (visited.add(neighbor)) {
                    queue.add(neighbor)
                }
                if (visited.size >= count) break
            }
        }

        return visited.toList()
    }

}
