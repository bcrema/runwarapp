package com.runwar.domain.user

import com.runwar.config.RateLimitExceededException
import org.springframework.stereotype.Component
import java.time.Duration
import java.time.Instant
import com.github.benmanes.caffeine.cache.Cache
import com.github.benmanes.caffeine.cache.Caffeine

@Component
class AuthRateLimiter(
    private val maxAttempts: Int = 5,
    private val window: Duration = Duration.ofMinutes(10)
) {
    private val attempts: Cache<String, AttemptWindow> = Caffeine.newBuilder()
        .expireAfterWrite(window)
        .build()

    fun check(key: String) {
        val now = Instant.now()
        val windowState = attempts.asMap().compute(key) { _, existing ->
            val current = existing ?: AttemptWindow(0, now)
            if (current.windowStart.plus(window).isBefore(now)) {
                AttemptWindow(1, now)
            } else {
                current.count += 1
                current
            }
        } ?: AttemptWindow(0, now)

        if (windowState.count > maxAttempts) {
            throw RateLimitExceededException("Too many attempts, please try again later")
        }
    }

    private data class AttemptWindow(
        var count: Int,
        var windowStart: Instant
    )
}
