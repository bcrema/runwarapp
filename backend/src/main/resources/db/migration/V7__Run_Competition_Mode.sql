ALTER TABLE runs
    ADD COLUMN competition_mode VARCHAR(20) NOT NULL DEFAULT 'TRAINING';

ALTER TABLE runs
    ADD CONSTRAINT check_run_competition_mode CHECK (competition_mode IN ('COMPETITIVE', 'TRAINING'));
