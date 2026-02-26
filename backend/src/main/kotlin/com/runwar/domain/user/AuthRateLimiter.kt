package com.runwar.domain.user

import com.runwar.config.RateLimitExceededException
import org.springframework.stereotype.Component
import java.time.Duration
import com.github.benmanes.caffeine.cache.Cache
import com.github.benmanes.caffeine.cache.Caffeine

@Component
class AuthRateLimiter(
    private val maxAttempts: Int = 5,
    private val window: Duration = Duration.ofMinutes(10)
) {
    private val attempts: Cache<String, Int> = Caffeine.newBuilder()
        .expireAfterWrite(window)
        .build()

    fun ensureAllowed(key: String) {
        val count = attempts.getIfPresent(key) ?: 0
        if (count >= maxAttempts) {
            throw RateLimitExceededException("Too many attempts, please try again later")
        }
    }

    fun recordFailure(key: String) {
        attempts.asMap().compute(key) { _, existing ->
            (existing ?: 0) + 1
        }
    }

    fun reset(key: String) {
        attempts.invalidate(key)
    }

    fun check(key: String) {
        val count = attempts.asMap().compute(key) { _, existing ->
            (existing ?: 0) + 1
        } ?: 0
        if (count > maxAttempts) {
            throw RateLimitExceededException("Too many attempts, please try again later")
        }
    }
}
