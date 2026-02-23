package com.runwar.notification

import com.runwar.domain.quadra.Quadra
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service

@Service
class NotificationService {
    
    private val logger = LoggerFactory.getLogger(NotificationService::class.java)
    
    /**
     * Notify when a quadra is taken over by a new owner
     */
    fun notifyQuadraTakeover(quadra: Quadra) {
        logger.info("Quadra ${quadra.id} was taken over. New owner: ${quadra.ownerId}")
        // TODO: Implement push notifications / in-app notifications
        // For MVP: Just log, notifications will be polled via API
    }
    
    /**
     * Notify when a quadra enters dispute state (shield < threshold)
     */
    fun notifyQuadraInDispute(quadra: Quadra) {
        logger.info("Quadra ${quadra.id} is now in dispute. Shield: ${quadra.shield}")
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
