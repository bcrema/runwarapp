package com.runwar.domain.user

import com.runwar.config.RateLimitExceededException
import org.junit.jupiter.api.Assertions.assertDoesNotThrow
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Test
import java.time.Duration

class AuthRateLimiterTest {

    @Test
    fun `allows up to maxAttempts within window`() {
        val limiter = AuthRateLimiter(maxAttempts = 2, window = Duration.ofMinutes(10))

        assertDoesNotThrow { limiter.check("login:ip:127.0.0.1") }
        assertDoesNotThrow { limiter.check("login:ip:127.0.0.1") }
        assertThrows(RateLimitExceededException::class.java) {
            limiter.check("login:ip:127.0.0.1")
        }
    }

    @Test
    fun `limits are independent per key`() {
        val limiter = AuthRateLimiter(maxAttempts = 1, window = Duration.ofMinutes(10))

        assertDoesNotThrow { limiter.check("signup:email:a@b.com") }
        assertDoesNotThrow { limiter.check("signup:email:c@d.com") }
        assertThrows(RateLimitExceededException::class.java) {
            limiter.check("signup:email:a@b.com")
        }
    }

    @Test
    fun `ensureAllowed blocks only after max failed attempts`() {
        val limiter = AuthRateLimiter(maxAttempts = 2, window = Duration.ofMinutes(10))
        val key = "login:email:user@example.com"

        assertDoesNotThrow { limiter.ensureAllowed(key) }
        limiter.recordFailure(key)
        assertDoesNotThrow { limiter.ensureAllowed(key) }
        limiter.recordFailure(key)
        assertThrows(RateLimitExceededException::class.java) {
            limiter.ensureAllowed(key)
        }
    }

    @Test
    fun `reset clears failed attempts`() {
        val limiter = AuthRateLimiter(maxAttempts = 1, window = Duration.ofMinutes(10))
        val key = "login:ip:127.0.0.1"

        limiter.recordFailure(key)
        assertThrows(RateLimitExceededException::class.java) {
            limiter.ensureAllowed(key)
        }

        limiter.reset(key)
        assertDoesNotThrow { limiter.ensureAllowed(key) }
    }
}
