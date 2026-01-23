-- V4__User_Profile_Visibility.sql
-- Adds profile visibility, user name, and updated_at timestamp

ALTER TABLE users
    ADD COLUMN name VARCHAR(100),
    ADD COLUMN profile_visibility VARCHAR(10) NOT NULL DEFAULT 'PUBLIC',
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

UPDATE users
SET name = username,
    profile_visibility = CASE WHEN is_public THEN 'PUBLIC' ELSE 'PRIVATE' END,
    updated_at = NOW()
WHERE name IS NULL;

ALTER TABLE users
    ADD CONSTRAINT check_profile_visibility
    CHECK (profile_visibility IN ('PUBLIC', 'PRIVATE'));
