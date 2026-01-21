package com.runwar.config

import com.runwar.domain.user.UserRepository
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import com.fasterxml.jackson.databind.ObjectMapper
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter
import java.util.*

@Component
class JwtAuthenticationFilter(
    private val jwtService: JwtService,
    private val userRepository: UserRepository,
    private val objectMapper: ObjectMapper
) : OncePerRequestFilter() {
    
    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        val authHeader = request.getHeader("Authorization")
        
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response)
            return
        }
        
        val jwt = authHeader.substring(7)
        if (!jwtService.isTokenValid(jwt)) {
            writeUnauthorized(response)
            return
        }

        val userId = jwtService.extractUserId(jwt)
        if (userId == null) {
            writeUnauthorized(response)
            return
        }
        
        if (userId != null && SecurityContextHolder.getContext().authentication == null) {
            if (jwtService.isTokenValid(jwt)) {
                val user = userRepository.findById(userId).orElse(null)
                
                if (user != null) {
                    val userDetails = UserPrincipal(user)
                    val authToken = UsernamePasswordAuthenticationToken(
                        userDetails,
                        null,
                        userDetails.authorities
                    )
                    authToken.details = WebAuthenticationDetailsSource().buildDetails(request)
                    SecurityContextHolder.getContext().authentication = authToken
                }
            }
        }
        
        filterChain.doFilter(request, response)
    }

    private fun writeUnauthorized(response: HttpServletResponse) {
        response.status = HttpServletResponse.SC_UNAUTHORIZED
        response.contentType = "application/json"
        val payload = ApiErrorResponse("UNAUTHORIZED", "Invalid token")
        objectMapper.writeValue(response.outputStream, payload)
    }
}
