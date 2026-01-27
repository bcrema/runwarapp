CREATE TABLE run_telemetry_events (
    id UUID PRIMARY KEY,
    run_id UUID NOT NULL,
    user_id UUID NOT NULL,
    origin VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    is_loop_valid BOOLEAN NOT NULL,
    loop_distance_meters DOUBLE PRECISION NOT NULL,
    loop_duration_seconds INTEGER NOT NULL,
    closure_meters DOUBLE PRECISION NOT NULL,
    coverage_pct DOUBLE PRECISION NOT NULL,
    primary_tile_id VARCHAR(32),
    tiles_covered TEXT[] NOT NULL,
    tiles_covered_count INTEGER NOT NULL,
    action_type VARCHAR(20),
    action_success BOOLEAN NOT NULL,
    action_reason VARCHAR(80),
    shield_before INTEGER,
    shield_after INTEGER,
    cooldown_until TIMESTAMPTZ,
    user_cap_reached BOOLEAN NOT NULL,
    bandeira_cap_reached BOOLEAN NOT NULL,
    actions_today INTEGER NOT NULL,
    bandeira_actions_today INTEGER,
    user_actions_remaining INTEGER NOT NULL,
    bandeira_actions_remaining INTEGER,
    fraud_flags TEXT[] NOT NULL,
    rejection_reasons TEXT[] NOT NULL,
    payload_json TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_run_telemetry_events_created_at ON run_telemetry_events (created_at);
CREATE INDEX idx_run_telemetry_events_run_id ON run_telemetry_events (run_id);
