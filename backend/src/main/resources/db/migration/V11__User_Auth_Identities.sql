CREATE TABLE user_auth_identities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    provider VARCHAR(20) NOT NULL,
    provider_subject VARCHAR(255) NOT NULL,
    provider_email VARCHAR(255),
    email_verified BOOLEAN NOT NULL DEFAULT false,
    display_name VARCHAR(255),
    avatar_url VARCHAR(512),
    last_login_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_user_auth_identity_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uq_user_auth_identity_provider_subject UNIQUE (provider, provider_subject),
    CONSTRAINT uq_user_auth_identity_user_provider UNIQUE (user_id, provider)
);

CREATE INDEX idx_user_auth_identities_user ON user_auth_identities (user_id);
CREATE INDEX idx_user_auth_identities_email ON user_auth_identities (provider_email);
