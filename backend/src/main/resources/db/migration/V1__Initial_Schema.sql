-- V1__Initial_Schema.sql
-- RunWar MVP Database Schema

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(30) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(512),
    is_public BOOLEAN NOT NULL DEFAULT true,
    bandeira_id UUID,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    total_runs INTEGER NOT NULL DEFAULT 0,
    total_distance DECIMAL(12, 2) NOT NULL DEFAULT 0,
    total_tiles_conquered INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT check_role CHECK (role IN ('ADMIN', 'COACH', 'MEMBER'))
);

-- Bandeiras (Teams/Flags)
CREATE TABLE bandeiras (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    slug VARCHAR(50) NOT NULL UNIQUE,
    category VARCHAR(20) NOT NULL,
    color VARCHAR(7) NOT NULL, -- hex color #RRGGBB
    logo_url VARCHAR(512),
    description VARCHAR(500),
    created_by UUID NOT NULL,
    daily_action_cap INTEGER NOT NULL DEFAULT 60,
    member_count INTEGER NOT NULL DEFAULT 1,
    total_tiles INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT check_category CHECK (category IN ('ASSESSORIA', 'ACADEMIA', 'BOX', 'GRUPO')),
    CONSTRAINT fk_bandeira_creator FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Add foreign key from users to bandeiras (after bandeiras is created)
ALTER TABLE users ADD CONSTRAINT fk_user_bandeira 
    FOREIGN KEY (bandeira_id) REFERENCES bandeiras(id) ON DELETE SET NULL;

-- Tiles (Hexagonal territories)
CREATE TABLE tiles (
    id VARCHAR(20) PRIMARY KEY, -- H3 index
    center GEOMETRY(Point, 4326) NOT NULL,
    owner_type VARCHAR(10),
    owner_id UUID,
    shield INTEGER NOT NULL DEFAULT 0,
    cooldown_until TIMESTAMPTZ,
    guardian_id UUID,
    guardian_contribution INTEGER NOT NULL DEFAULT 0,
    last_defense_at TIMESTAMPTZ,
    last_action_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT check_owner_type CHECK (owner_type IS NULL OR owner_type IN ('SOLO', 'BANDEIRA')),
    CONSTRAINT check_shield CHECK (shield >= 0 AND shield <= 100),
    CONSTRAINT fk_tile_guardian FOREIGN KEY (guardian_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create spatial index on tiles
CREATE INDEX idx_tiles_center ON tiles USING GIST (center);
CREATE INDEX idx_tiles_owner ON tiles (owner_id) WHERE owner_id IS NOT NULL;

-- Runs
CREATE TABLE runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    gpx_url VARCHAR(512),
    distance DECIMAL(10, 2) NOT NULL, -- meters
    duration INTEGER NOT NULL, -- seconds
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    is_loop_valid BOOLEAN NOT NULL DEFAULT false,
    loop_distance DECIMAL(10, 2),
    closing_distance DECIMAL(8, 2),
    territory_action VARCHAR(20),
    target_tile_id VARCHAR(20),
    is_valid_for_territory BOOLEAN NOT NULL DEFAULT false,
    fraud_flags TEXT[] DEFAULT '{}',
    polyline TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT check_territory_action CHECK (territory_action IS NULL OR territory_action IN ('CONQUEST', 'ATTACK', 'DEFENSE')),
    CONSTRAINT fk_run_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_run_tile FOREIGN KEY (target_tile_id) REFERENCES tiles(id) ON DELETE SET NULL
);

CREATE INDEX idx_runs_user ON runs (user_id, created_at DESC);
CREATE INDEX idx_runs_territory ON runs (is_valid_for_territory, created_at DESC) WHERE is_valid_for_territory = true;

-- Territory Actions
CREATE TABLE territory_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID,
    user_id UUID NOT NULL,
    bandeira_id UUID,
    tile_id VARCHAR(20) NOT NULL,
    action_type VARCHAR(20) NOT NULL,
    shield_change INTEGER NOT NULL,
    shield_before INTEGER NOT NULL,
    shield_after INTEGER NOT NULL,
    owner_changed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT check_action_type CHECK (action_type IN ('CONQUEST', 'ATTACK', 'DEFENSE')),
    CONSTRAINT fk_action_run FOREIGN KEY (run_id) REFERENCES runs(id) ON DELETE SET NULL,
    CONSTRAINT fk_action_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_action_bandeira FOREIGN KEY (bandeira_id) REFERENCES bandeiras(id) ON DELETE SET NULL,
    CONSTRAINT fk_action_tile FOREIGN KEY (tile_id) REFERENCES tiles(id) ON DELETE CASCADE
);

CREATE INDEX idx_actions_user ON territory_actions (user_id, created_at DESC);
CREATE INDEX idx_actions_tile ON territory_actions (tile_id, created_at DESC);
CREATE INDEX idx_actions_bandeira ON territory_actions (bandeira_id, created_at DESC) WHERE bandeira_id IS NOT NULL;

-- Seasons
CREATE TABLE seasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Season Scores (daily snapshots for scoring)
CREATE TABLE season_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    season_id UUID NOT NULL,
    bandeira_id UUID,
    user_id UUID,
    score_type VARCHAR(20) NOT NULL,
    daily_points INTEGER NOT NULL DEFAULT 0,
    cluster_bonus INTEGER NOT NULL DEFAULT 0,
    total_points INTEGER NOT NULL DEFAULT 0,
    date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT check_score_type CHECK (score_type IN ('BANDEIRA', 'SOLO')),
    CONSTRAINT fk_score_season FOREIGN KEY (season_id) REFERENCES seasons(id) ON DELETE CASCADE,
    CONSTRAINT fk_score_bandeira FOREIGN KEY (bandeira_id) REFERENCES bandeiras(id) ON DELETE CASCADE,
    CONSTRAINT fk_score_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT unique_daily_score UNIQUE (season_id, bandeira_id, user_id, date)
);

-- Badges
CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    icon_url VARCHAR(512),
    criteria JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User Badges
CREATE TABLE user_badges (
    user_id UUID NOT NULL,
    badge_id UUID NOT NULL,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (user_id, badge_id),
    CONSTRAINT fk_user_badge_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_badge_badge FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE
);

-- Weekly Missions
CREATE TABLE weekly_missions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    week_start DATE NOT NULL,
    mission_type VARCHAR(50) NOT NULL,
    target_value INTEGER NOT NULL,
    current_value INTEGER NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_mission_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT unique_weekly_mission UNIQUE (user_id, week_start, mission_type)
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT,
    data JSONB DEFAULT '{}',
    read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_user ON notifications (user_id, read, created_at DESC);

-- Insert default badges
INSERT INTO badges (slug, name, description, criteria) VALUES
('first_conquest', 'Primeiro Território', 'Conquiste seu primeiro tile', '{"type": "conquest", "count": 1}'),
('conqueror_5', 'Conquistador', 'Conquiste 5 tiles', '{"type": "conquest", "count": 5}'),
('defender', 'Defensor', 'Defenda um tile em disputa', '{"type": "defense_dispute", "count": 1}'),
('warrior', 'Guerreiro', 'Realize 10 ataques bem-sucedidos', '{"type": "attack", "count": 10}'),
('marathon', 'Maratonista', 'Complete uma corrida de 10km ou mais', '{"type": "distance", "meters": 10000}'),
('consistent', 'Consistente', 'Corra 7 dias seguidos', '{"type": "streak", "days": 7}');

-- Create first season
INSERT INTO seasons (name, start_date, end_date, is_active) VALUES
('Temporada 1', CURRENT_DATE, CURRENT_DATE + INTERVAL '6 weeks', true);
