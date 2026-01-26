package com.runwar.domain.run

import com.runwar.config.GameProperties
import com.runwar.domain.territory.TerritoryActionRepository
import com.runwar.domain.user.User
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID
import org.springframework.stereotype.Service

@Service
class CapsService(
        private val territoryActionRepository: TerritoryActionRepository,
        private val gameProperties: GameProperties
) {
        companion object {
                private val DEFAULT_ZONE_OFFSET: ZoneOffset = ZoneOffset.ofHours(-3)
        }

        data class CapsCheck(
                val actionsToday: Int,
                val bandeiraActionsToday: Int?,
                val userCapReached: Boolean,
                val bandeiraCapReached: Boolean
        )

        fun checkCaps(user: User): CapsCheck {
                val actionsToday = getDailyActionCount(user.id)
                val bandeiraActionsToday = user.bandeira?.let { getBandeiraDailyActionCount(it.id) }
                val userCapReached = actionsToday >= gameProperties.userDailyActionCap
                val bandeiraCapReached =
                        user.bandeira?.let { bandeira ->
                                (bandeiraActionsToday ?: 0) >= bandeira.dailyActionCap
                        }
                                ?: false

                return CapsCheck(
                        actionsToday = actionsToday,
                        bandeiraActionsToday = bandeiraActionsToday,
                        userCapReached = userCapReached,
                        bandeiraCapReached = bandeiraCapReached
                )
        }

        fun getDailyActionCount(userId: UUID): Int {
                return territoryActionRepository.countUserActionsToday(userId, startOfDay())
        }

        fun getBandeiraDailyActionCount(bandeiraId: UUID): Int {
                return territoryActionRepository.countBandeiraActionsToday(
                        bandeiraId,
                        startOfDay()
                )
        }

        private fun startOfDay(): Instant {
                return LocalDate.now(DEFAULT_ZONE_OFFSET).atStartOfDay(DEFAULT_ZONE_OFFSET).toInstant()
        }
}
