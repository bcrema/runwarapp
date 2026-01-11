package com.runwar.config

import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class GlobalExceptionHandler {
    
    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)
    
    data class ErrorResponse(
        val error: String,
        val message: String,
        val details: Map<String, String>? = null
    )
    
    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgument(e: IllegalArgumentException): ResponseEntity<ErrorResponse> {
        logger.warn("Bad request: ${e.message}")
        return ResponseEntity.badRequest().body(
            ErrorResponse("BAD_REQUEST", e.message ?: "Invalid request")
        )
    }
    
    @ExceptionHandler(IllegalStateException::class)
    fun handleIllegalState(e: IllegalStateException): ResponseEntity<ErrorResponse> {
        logger.warn("Illegal state: ${e.message}")
        return ResponseEntity.status(HttpStatus.CONFLICT).body(
            ErrorResponse("CONFLICT", e.message ?: "Operation not allowed in current state")
        )
    }
    
    @ExceptionHandler(BadCredentialsException::class)
    fun handleBadCredentials(e: BadCredentialsException): ResponseEntity<ErrorResponse> {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
            ErrorResponse("UNAUTHORIZED", "Invalid credentials")
        )
    }
    
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(e: MethodArgumentNotValidException): ResponseEntity<ErrorResponse> {
        val errors = e.bindingResult.allErrors.associate { error ->
            val fieldName = (error as? FieldError)?.field ?: "unknown"
            fieldName to (error.defaultMessage ?: "Invalid value")
        }
        
        return ResponseEntity.badRequest().body(
            ErrorResponse(
                error = "VALIDATION_ERROR",
                message = "Request validation failed",
                details = errors
            )
        )
    }
    
    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(e: AccessDeniedException): ResponseEntity<ErrorResponse> {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
            ErrorResponse("FORBIDDEN", "Access denied")
        )
    }
    
    @ExceptionHandler(Exception::class)
    fun handleGeneral(e: Exception): ResponseEntity<ErrorResponse> {
        logger.error("Unhandled exception", e)
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            ErrorResponse("INTERNAL_ERROR", "An unexpected error occurred")
        )
    }
}
