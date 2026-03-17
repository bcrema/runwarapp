package com.runwar.domain.user

enum class SocialAuthProvider(val apiValue: String) {
    GOOGLE("google"),
    APPLE("apple");

    companion object {
        fun from(value: String): SocialAuthProvider {
            return entries.firstOrNull { it.apiValue.equals(value.trim(), ignoreCase = true) }
                ?: throw IllegalArgumentException("Unsupported social auth provider")
        }
    }
}
