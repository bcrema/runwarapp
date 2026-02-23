package com.runwar.domain.quadra

import java.sql.Connection
import java.sql.DriverManager
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class V9TileToQuadraCutoverMigrationTest {

    @Test
    fun `migration renames physical objects and preserves data`() {
        val jdbcUrl = "jdbc:h2:mem:v9_migration_test;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"

        DriverManager.getConnection(jdbcUrl, "sa", "").use { connection ->
            createBaselineSchema(connection)
            seedBaselineData(connection)

            val tilesCountBefore = count(connection, "SELECT COUNT(*) FROM tiles")
            val runsTargetBefore = count(connection, "SELECT COUNT(*) FROM runs WHERE target_tile_id IS NOT NULL")
            val actionsBefore = count(connection, "SELECT COUNT(*) FROM territory_actions")
            val telemetryPrimaryBefore = count(connection, "SELECT COUNT(*) FROM run_telemetry_events WHERE primary_tile_id IS NOT NULL")

            applyMigration(connection)

            assertEquals(tilesCountBefore, count(connection, "SELECT COUNT(*) FROM quadras"))
            assertEquals(runsTargetBefore, count(connection, "SELECT COUNT(*) FROM runs WHERE target_quadra_id IS NOT NULL"))
            assertEquals(actionsBefore, count(connection, "SELECT COUNT(*) FROM territory_actions"))
            assertEquals(telemetryPrimaryBefore, count(connection, "SELECT COUNT(*) FROM run_telemetry_events WHERE primary_quadra_id IS NOT NULL"))

            assertEquals(0, count(connection, "SELECT COUNT(*) FROM territory_actions ta LEFT JOIN quadras q ON q.id = ta.quadra_id WHERE q.id IS NULL"))
            assertEquals(1, count(connection, "SELECT COUNT(*) FROM quadras WHERE id = '8928308280fffff'"))

            assertEquals(0, count(connection, "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'tiles'"))
            assertEquals(0, count(connection, "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'runs' AND column_name = 'target_tile_id'"))
            assertEquals(0, count(connection, "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'territory_actions' AND column_name = 'tile_id'"))
            assertEquals(0, count(connection, "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'run_telemetry_events' AND column_name = 'primary_tile_id'"))

            assertEquals(1, count(connection, "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'total_quadras_conquered'"))
            assertEquals(1, count(connection, "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'bandeiras' AND column_name = 'total_quadras'"))
        }
    }

    private fun createBaselineSchema(connection: Connection) {
        connection.createStatement().use { statement ->
            statement.execute("CREATE TABLE users (id UUID PRIMARY KEY, total_tiles_conquered INTEGER NOT NULL DEFAULT 0)")
            statement.execute("CREATE TABLE bandeiras (id UUID PRIMARY KEY, total_tiles INTEGER NOT NULL DEFAULT 0)")
            statement.execute("CREATE TABLE badges (id UUID PRIMARY KEY, description VARCHAR(500))")

            statement.execute(
                """
                CREATE TABLE tiles (
                    id VARCHAR(20) PRIMARY KEY,
                    center VARCHAR(100),
                    owner_id UUID,
                    guardian_id UUID,
                    CONSTRAINT fk_tile_guardian FOREIGN KEY (guardian_id) REFERENCES users(id)
                )
                """.trimIndent()
            )
            statement.execute("CREATE INDEX idx_tiles_center ON tiles (id)")
            statement.execute("CREATE INDEX idx_tiles_owner ON tiles (owner_id)")

            statement.execute(
                """
                CREATE TABLE runs (
                    id UUID PRIMARY KEY,
                    target_tile_id VARCHAR(20),
                    CONSTRAINT fk_run_tile FOREIGN KEY (target_tile_id) REFERENCES tiles(id)
                )
                """.trimIndent()
            )

            statement.execute(
                """
                CREATE TABLE territory_actions (
                    id UUID PRIMARY KEY,
                    tile_id VARCHAR(20) NOT NULL,
                    created_at TIMESTAMP,
                    CONSTRAINT fk_action_tile FOREIGN KEY (tile_id) REFERENCES tiles(id)
                )
                """.trimIndent()
            )
            statement.execute("CREATE INDEX idx_actions_tile ON territory_actions (tile_id, created_at)")

            statement.execute(
                """
                CREATE TABLE run_telemetry_events (
                    id UUID PRIMARY KEY,
                    primary_tile_id VARCHAR(32),
                    tiles_covered VARCHAR,
                    tiles_covered_count INTEGER
                )
                """.trimIndent()
            )
        }
    }

    private fun seedBaselineData(connection: Connection) {
        connection.createStatement().use { statement ->
            statement.execute("INSERT INTO users (id, total_tiles_conquered) VALUES ('00000000-0000-0000-0000-000000000001', 7)")
            statement.execute("INSERT INTO bandeiras (id, total_tiles) VALUES ('00000000-0000-0000-0000-000000000011', 5)")
            statement.execute("INSERT INTO badges (id, description) VALUES ('00000000-0000-0000-0000-000000000021', 'Conquiste 5 tiles')")

            statement.execute(
                """
                INSERT INTO tiles (id, center, owner_id, guardian_id) VALUES
                ('8928308280fffff', 'POINT(-49.27 -25.43)', '00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001'),
                ('89283082813ffff', 'POINT(-49.28 -25.44)', '00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001')
                """.trimIndent()
            )

            statement.execute("INSERT INTO runs (id, target_tile_id) VALUES ('00000000-0000-0000-0000-000000000031', '8928308280fffff')")
            statement.execute("INSERT INTO territory_actions (id, tile_id, created_at) VALUES ('00000000-0000-0000-0000-000000000041', '8928308280fffff', CURRENT_TIMESTAMP())")
            statement.execute("INSERT INTO run_telemetry_events (id, primary_tile_id, tiles_covered, tiles_covered_count) VALUES ('00000000-0000-0000-0000-000000000051', '8928308280fffff', '8928308280fffff', 1)")
        }
    }

    private fun applyMigration(connection: Connection) {
        val resource = javaClass.getResource("/db/migration/V9__Tile_To_Quadra_Cutover.sql")
        assertNotNull(resource, "V9 migration file must exist")

        val script =
            resource!!.readText()
                .lineSequence()
                .filterNot { it.trimStart().startsWith("--") }
                .joinToString("\n")

        val statements =
            script
                .split(';')
                .map { it.trim() }
                .filter { it.isNotEmpty() }

        connection.createStatement().use { statement ->
            statements.forEach(statement::execute)
        }
    }

    private fun count(connection: Connection, sql: String): Int {
        connection.createStatement().use { statement ->
            statement.executeQuery(sql).use { rs ->
                assertTrue(rs.next())
                return rs.getInt(1)
            }
        }
    }
}
