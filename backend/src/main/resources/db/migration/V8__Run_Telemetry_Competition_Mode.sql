ALTER TABLE run_telemetry_events
    ADD COLUMN competition_mode VARCHAR(20) NOT NULL DEFAULT 'TRAINING';

ALTER TABLE run_telemetry_events
    ADD CONSTRAINT check_run_telemetry_competition_mode CHECK (competition_mode IN ('COMPETITIVE', 'TRAINING'));
