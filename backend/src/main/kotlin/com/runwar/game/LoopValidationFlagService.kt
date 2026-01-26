package com.runwar.game

import com.fasterxml.jackson.databind.ObjectMapper
import java.nio.file.Files
import java.nio.file.Paths
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service

@Service
class LoopValidationFlagService(
    private val objectMapper: ObjectMapper,
    @Value("\${runwar.loop-validation-flags-path:}") private val flagsPath: String,
    @Value("\${runwar.loop-validation-default-city:curitiba}") private val defaultCity: String
) {

    private val logger = LoggerFactory.getLogger(javaClass)
    private var cachedConfig: LoopValidationFlagConfig? = null
    private var cachedLastModified: Long? = null

    fun resolveFlags(bandeiraSlug: String?, city: String? = null): LoopValidationFlags {
        val config = loadConfig()
        val normalizedBandeira = bandeiraSlug?.lowercase()
        val normalizedCity = (city ?: defaultCity).lowercase()

        return config?.let { loaded ->
            when {
                normalizedBandeira != null ->
                    loaded.byBandeira.findByKey(normalizedBandeira)
                        ?: loaded.byCity.findByKey(normalizedCity)
                        ?: loaded.defaults
                else ->
                    loaded.byCity.findByKey(normalizedCity)
                        ?: loaded.defaults
            }
        } ?: LoopValidationFlags()
    }

    private fun loadConfig(): LoopValidationFlagConfig? {
        if (flagsPath.isBlank()) {
            return null
        }

        val path = Paths.get(flagsPath)
        if (!Files.exists(path)) {
            return null
        }

        val lastModified = Files.getLastModifiedTime(path).toMillis()
        if (cachedConfig != null && cachedLastModified == lastModified) {
            return cachedConfig
        }

        return runCatching {
                objectMapper.readValue(path.toFile(), LoopValidationFlagConfig::class.java)
            }
            .onFailure { error ->
                logger.warn("Failed to load loop validation flags from {}", path, error)
            }
            .getOrNull()
            ?.also {
                cachedConfig = it
                cachedLastModified = lastModified
            }
            ?: cachedConfig
    }

    private fun Map<String, LoopValidationFlags>.findByKey(key: String): LoopValidationFlags? {
        return entries.firstOrNull { it.key.equals(key, ignoreCase = true) }?.value
    }
}

data class LoopValidationFlagConfig(
    val defaults: LoopValidationFlags = LoopValidationFlags(),
    val byCity: Map<String, LoopValidationFlags> = emptyMap(),
    val byBandeira: Map<String, LoopValidationFlags> = emptyMap()
)
