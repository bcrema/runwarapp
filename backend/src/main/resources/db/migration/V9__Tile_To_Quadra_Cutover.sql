-- Cutover físico de tiles para quadras.
-- Estratégia: renomeação in-place para preservar 100% dos registros existentes.

ALTER TABLE tiles RENAME TO quadras;

ALTER TABLE runs RENAME COLUMN target_tile_id TO target_quadra_id;
ALTER TABLE territory_actions RENAME COLUMN tile_id TO quadra_id;
ALTER TABLE run_telemetry_events RENAME COLUMN primary_tile_id TO primary_quadra_id;
ALTER TABLE run_telemetry_events RENAME COLUMN tiles_covered TO quadras_covered;
ALTER TABLE run_telemetry_events RENAME COLUMN tiles_covered_count TO quadras_covered_count;
ALTER TABLE users RENAME COLUMN total_tiles_conquered TO total_quadras_conquered;
ALTER TABLE bandeiras RENAME COLUMN total_tiles TO total_quadras;

ALTER TABLE quadras RENAME CONSTRAINT fk_tile_guardian TO fk_quadra_guardian;
ALTER TABLE runs RENAME CONSTRAINT fk_run_tile TO fk_run_quadra;
ALTER TABLE territory_actions RENAME CONSTRAINT fk_action_tile TO fk_action_quadra;

ALTER INDEX idx_tiles_center RENAME TO idx_quadras_center;
ALTER INDEX idx_tiles_owner RENAME TO idx_quadras_owner;
ALTER INDEX idx_actions_tile RENAME TO idx_actions_quadra;

UPDATE badges
SET description = REPLACE(description, ' tiles', ' quadras')
WHERE description LIKE '% tiles%';
