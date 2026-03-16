package com.runwar.config

class UnauthorizedException(message: String) : RuntimeException(message)

class RateLimitExceededException(message: String) : RuntimeException(message)

class SocialLinkRequiredException(
    val linkToken: String,
    val provider: String,
    val emailMasked: String
) : RuntimeException("Account linking required")
