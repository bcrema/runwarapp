package com.runwar.config

import com.runwar.domain.user.SocialAuthProvider
import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "auth.social")
data class SocialAuthProperties(
    val google: ProviderProperties = ProviderProperties(
        jwkSetUri = "https://www.googleapis.com/oauth2/v3/certs",
        issuers = listOf("https://accounts.google.com", "accounts.google.com")
    ),
    val apple: ProviderProperties = ProviderProperties(
        jwkSetUri = "https://appleid.apple.com/auth/keys",
        issuers = listOf("https://appleid.apple.com")
    )
) {
    data class ProviderProperties(
        val clientIds: List<String> = emptyList(),
        val jwkSetUri: String = "",
        val issuers: List<String> = emptyList()
    )

    fun provider(provider: SocialAuthProvider): ProviderProperties {
        return when (provider) {
            SocialAuthProvider.GOOGLE -> google
            SocialAuthProvider.APPLE -> apple
        }
    }
}
