package com.runwar.domain.bandeira

import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.transaction.annotation.Transactional

class BandeiraServiceTest {

    @Test
    fun `bandeira service is marked as read only transactional`() {
        val transactional = BandeiraService::class.java.getAnnotation(Transactional::class.java)

        assertNotNull(transactional)
        assertTrue(transactional.readOnly)
    }
}
