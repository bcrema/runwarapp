package com.runwar.config

class UnauthorizedException(message: String) : RuntimeException(message)

class RateLimitExceededException(message: String) : RuntimeException(message)
