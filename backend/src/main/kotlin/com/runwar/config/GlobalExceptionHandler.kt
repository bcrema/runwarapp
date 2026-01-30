package com.runwar.config

import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.security.access.AccessDeniedException
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.server.ResponseStatusException

@RestControllerAdvice
class GlobalExceptionHandler {
    
    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)
    
    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgument(e: IllegalArgumentException): ResponseEntity<ApiErrorResponse> {
        logger.warn("Bad request: ${e.message}")
        return ResponseEntity.badRequest().body(
            ApiErrorResponse("BAD_REQUEST", e.message ?: "Invalid request")
        )
    }
    
    @ExceptionHandler(IllegalStateException::class)
    fun handleIllegalState(e: IllegalStateException): ResponseEntity<ApiErrorResponse> {
        logger.warn("Illegal state: ${e.message}")
        return ResponseEntity.status(HttpStatus.CONFLICT).body(
            ApiErrorResponse("CONFLICT", e.message ?: "Operation not allowed in current state")
        )
    }
    
    @ExceptionHandler(BadCredentialsException::class)
    fun handleBadCredentials(e: BadCredentialsException): ResponseEntity<ApiErrorResponse> {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
            ApiErrorResponse("UNAUTHORIZED", "Invalid credentials")
        )
    }

    @ExceptionHandler(UnauthorizedException::class)
    fun handleUnauthorized(e: UnauthorizedException): ResponseEntity<ApiErrorResponse> {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
            ApiErrorResponse("UNAUTHORIZED", e.message ?: "Unauthorized")
        )
    }

    @ExceptionHandler(RateLimitExceededException::class)
    fun handleRateLimitExceeded(e: RateLimitExceededException): ResponseEntity<ApiErrorResponse> {
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(
            ApiErrorResponse("RATE_LIMITED", e.message ?: "Too many requests")
        )
    }
    
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(e: MethodArgumentNotValidException): ResponseEntity<ApiErrorResponse> {
        val errors = e.bindingResult.allErrors.associate { error ->
            val fieldName = (error as? FieldError)?.field ?: "unknown"
            fieldName to (error.defaultMessage ?: "Invalid value")
        }
        
        return ResponseEntity.badRequest().body(
            ApiErrorResponse(
                error = "VALIDATION_ERROR",
                message = "Request validation failed",
                details = errors
            )
        )
    }
    
    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(e: AccessDeniedException): ResponseEntity<ApiErrorResponse> {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
            ApiErrorResponse("FORBIDDEN", "Access denied")
        )
    }

    @ExceptionHandler(ResponseStatusException::class)
    fun handleResponseStatus(e: ResponseStatusException): ResponseEntity<ApiErrorResponse> {
        val status = e.statusCode
        val error = (status as? HttpStatus)?.name ?: status.toString()
        val message = e.reason ?: "Request failed"
        return ResponseEntity.status(status).body(ApiErrorResponse(error, message))
    }
    
    @ExceptionHandler(Exception::class)
    fun handleGeneral(e: Exception): ResponseEntity<ApiErrorResponse> {
        logger.error("Unhandled exception", e)
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            ApiErrorResponse("INTERNAL_ERROR", "An unexpected error occurred")
        )
    }
}
