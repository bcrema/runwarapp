-- Normalize legacy run origins to supported enum values

UPDATE runs
SET origin = 'IMPORT'
WHERE origin = 'LEGACY';

ALTER TABLE runs
    DROP CONSTRAINT IF EXISTS check_run_origin;

ALTER TABLE runs
    ADD CONSTRAINT check_run_origin CHECK (origin IN ('IOS', 'WEB', 'IMPORT'));
