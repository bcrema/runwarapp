package com.runwar.notification

import com.runwar.domain.tile.Tile
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service

@Service
class NotificationService {
    
    private val logger = LoggerFactory.getLogger(NotificationService::class.java)
    
    /**
     * Notify when a tile is taken over by a new owner
     */
    fun notifyTileTakeover(tile: Tile) {
        logger.info("Tile ${tile.id} was taken over. New owner: ${tile.ownerId}")
        // TODO: Implement push notifications / in-app notifications
        // For MVP: Just log, notifications will be polled via API
    }
    
    /**
     * Notify when a tile enters dispute state (shield < threshold)
     */
    fun notifyTileInDispute(tile: Tile) {
        logger.info("Tile ${tile.id} is now in dispute. Shield: ${tile.shield}")
        // TODO: Implement push notifications
    }
    
    /**
     * Send daily digest to users
     */
    fun sendDailyDigest(userId: java.util.UUID) {
        logger.info("Sending daily digest to user $userId")
        // TODO: Implement email/push digest
    }
}
