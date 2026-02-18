package com.runwar.domain.run

import java.lang.Math.multiplyExact
import java.time.Instant

object RunTimestampNormalizer {
    private const val EPOCH_MILLIS_THRESHOLD = 100_000_000_000L
    private const val MAX_FUTURE_OFFSET_MILLIS = 7L * 24 * 60 * 60 * 1000 // 7 days
    private const val MAX_PAST_OFFSET_MILLIS = 365L * 24 * 60 * 60 * 1000 // 365 days

    data class NormalizedTimestamps(
        val epochMillis: List<Long>,
        val instants: List<Instant>
    )

    /**
     * Accepts mixed timestamp formats (epoch seconds or epoch milliseconds).
     * Values lower than EPOCH_MILLIS_THRESHOLD are treated as seconds.
     */
    fun normalize(timestamps: List<Long>, nowMillis: Long = Instant.now().toEpochMilli()): NormalizedTimestamps {
        if (timestamps.isEmpty()) {
            throw IllegalArgumentException("At least one timestamp is required.")
        }

        val normalized = timestamps.map(::normalizeSingleTimestamp)

        val hasOutOfOrderTimestamps = normalized
            .windowed(size = 2, step = 1, partialWindows = false)
            .any { (prev, next) -> next < prev }
        if (hasOutOfOrderTimestamps) {
            throw IllegalArgumentException("Timestamps must be in non-decreasing chronological order.")
        }

        val hasUnreasonableTimestamp = normalized.any { ts ->
            ts > nowMillis + MAX_FUTURE_OFFSET_MILLIS || ts < nowMillis - MAX_PAST_OFFSET_MILLIS
        }
        if (hasUnreasonableTimestamp) {
            throw IllegalArgumentException("Timestamp values are not within an acceptable range.")
        }

        return NormalizedTimestamps(
            epochMillis = normalized,
            instants = normalized.map(Instant::ofEpochMilli)
        )
    }

    private fun normalizeSingleTimestamp(raw: Long): Long {
        if (raw >= EPOCH_MILLIS_THRESHOLD) {
            return raw
        }
        return try {
            multiplyExact(raw, 1000L)
        } catch (_: ArithmeticException) {
            throw IllegalArgumentException("Timestamp values are not within an acceptable range.")
        }
    }
}
