package com.runwar.domain.user

import com.runwar.config.SocialAuthProperties
import java.util.concurrent.ConcurrentHashMap
import org.springframework.security.oauth2.jwt.JwtDecoder
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder
import org.springframework.stereotype.Component

interface SocialJwtDecoderFactory {
    fun get(provider: SocialAuthProvider): JwtDecoder
}

@Component
class RemoteJwkSocialJwtDecoderFactory(
    private val socialAuthProperties: SocialAuthProperties
) : SocialJwtDecoderFactory {
    private val decoders = ConcurrentHashMap<SocialAuthProvider, JwtDecoder>()

    override fun get(provider: SocialAuthProvider): JwtDecoder {
        return decoders.computeIfAbsent(provider) { selectedProvider ->
            val config = socialAuthProperties.provider(selectedProvider)
            if (config.clientIds.isEmpty()) {
                throw IllegalStateException("Social auth provider ${selectedProvider.apiValue} is not configured")
            }
            NimbusJwtDecoder.withJwkSetUri(config.jwkSetUri).build()
        }
    }
}
