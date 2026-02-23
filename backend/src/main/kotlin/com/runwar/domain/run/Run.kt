package com.runwar.domain.run

import com.runwar.domain.tile.Tile
import com.runwar.domain.user.User
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.Instant
import java.util.*

@Entity
@Table(name = "runs")
class Run(
        @Id val id: UUID = UUID.randomUUID(),
        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "user_id", nullable = false)
        val user: User,
        @Enumerated(EnumType.STRING)
        @Column(nullable = false)
        var origin: RunOrigin = RunOrigin.IMPORT,
        @Enumerated(EnumType.STRING)
        @Column(nullable = false)
        var status: RunStatus = RunStatus.RECEIVED,
        @Column(name = "gpx_url") var gpxUrl: String? = null,
        @Column(nullable = false) val distance: BigDecimal, // meters
        @Column(nullable = false) val duration: Int, // seconds
        @Column(name = "start_time") val startTime: Instant,
        @Column(name = "end_time") val endTime: Instant,
        @Column(name = "min_lat") val minLat: Double? = null,
        @Column(name = "min_lng") val minLng: Double? = null,
        @Column(name = "max_lat") val maxLat: Double? = null,
        @Column(name = "max_lng") val maxLng: Double? = null,
        @Column(name = "is_loop_valid") var isLoopValid: Boolean = false,
        @Column(name = "loop_distance") var loopDistance: BigDecimal? = null,
        @Column(name = "closing_distance") var closingDistance: BigDecimal? = null,
        @Enumerated(EnumType.STRING)
        @Column(name = "competition_mode", nullable = false)
        var competitionMode: RunCompetitionMode = RunCompetitionMode.TRAINING,
        @Enumerated(EnumType.STRING)
        @Column(name = "territory_action")
        var territoryAction: TerritoryActionType? = null,
        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "target_tile_id")
        var targetTile: Tile? = null,
        @Column(name = "is_valid_for_territory") var isValidForTerritory: Boolean = false,
        @Column(name = "fraud_flags", columnDefinition = "text[]")
        var fraudFlags: List<String> = emptyList(),
        @Column(columnDefinition = "text")
        var polyline: String? = null, // encoded polyline for display
        @Column(name = "created_at") val createdAt: Instant = Instant.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Run) return false
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()
}

enum class TerritoryActionType {
    CONQUEST,
    ATTACK,
    DEFENSE
}

enum class RunOrigin {
    IOS,
    WEB,
    IMPORT
}

enum class RunStatus {
    RECEIVED,
    VALIDATED,
    REJECTED
}

enum class RunCompetitionMode {
    COMPETITIVE,
    TRAINING
}
