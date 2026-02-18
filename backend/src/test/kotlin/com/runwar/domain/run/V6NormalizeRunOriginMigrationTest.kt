package com.runwar.domain.run

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.Test
import java.sql.DriverManager
import java.sql.SQLException

class V6NormalizeRunOriginMigrationTest {

    @Test
    fun `migration normalizes LEGACY origin and keeps only supported values`() {
        val jdbcUrl = "jdbc:h2:mem:v6_migration_test;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"

        DriverManager.getConnection(jdbcUrl, "sa", "").use { connection ->
            connection.createStatement().use { statement ->
                statement.execute("CREATE TABLE runs (id INT PRIMARY KEY, origin VARCHAR(20) NOT NULL)")
                statement.execute(
                    "ALTER TABLE runs ADD CONSTRAINT check_run_origin CHECK (origin IN ('IOS', 'WEB', 'IMPORT', 'LEGACY'))"
                )
                statement.execute("INSERT INTO runs (id, origin) VALUES (1, 'LEGACY')")
                statement.execute("INSERT INTO runs (id, origin) VALUES (2, 'IOS')")
            }

            applyMigration(connection)

            connection.createStatement().use { statement ->
                statement.executeQuery("SELECT COUNT(*) FROM runs WHERE origin = 'LEGACY'").use { rs ->
                    rs.next()
                    assertEquals(0, rs.getInt(1))
                }
                statement.executeQuery("SELECT COUNT(*) FROM runs WHERE origin = 'IMPORT'").use { rs ->
                    rs.next()
                    assertEquals(1, rs.getInt(1))
                }

                assertThrows<SQLException> {
                    statement.execute("INSERT INTO runs (id, origin) VALUES (3, 'LEGACY')")
                }
            }
        }
    }

    private fun applyMigration(connection: java.sql.Connection) {
        val resource = javaClass.getResource("/db/migration/V6__Normalize_Run_Origin.sql")
        assertNotNull(resource, "V6 migration file must exist")
        val script = resource!!.readText()
            .lineSequence()
            .filterNot { it.trimStart().startsWith("--") }
            .joinToString("\n")

        val statements = script
            .split(';')
            .map { it.trim() }
            .filter { it.isNotEmpty() }

        connection.createStatement().use { statement ->
            statements.forEach(statement::execute)
        }
    }
}
