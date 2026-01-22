package com.runwar.config

data class ApiErrorResponse(
    val error: String,
    val message: String,
    val details: Map<String, String>? = null
)
