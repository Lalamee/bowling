CREATE TABLE IF NOT EXISTS refresh_tokens (
    refresh_token_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_hash VARCHAR(128) NOT NULL UNIQUE,
    issued_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    revoked_at TIMESTAMP WITHOUT TIME ZONE,
    revocation_reason VARCHAR(255),
    replaced_by_token_hash VARCHAR(128)
);

ALTER TABLE refresh_tokens
    ADD COLUMN IF NOT EXISTS revoked BOOLEAN DEFAULT FALSE;

ALTER TABLE refresh_tokens
    ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE refresh_tokens
    ADD COLUMN IF NOT EXISTS revocation_reason VARCHAR(255);

ALTER TABLE refresh_tokens
    ADD COLUMN IF NOT EXISTS replaced_by_token_hash VARCHAR(128);

UPDATE refresh_tokens SET revoked = FALSE WHERE revoked IS NULL;

ALTER TABLE refresh_tokens
    ALTER COLUMN revoked SET NOT NULL;

ALTER TABLE refresh_tokens
    ALTER COLUMN token_hash SET NOT NULL;

ALTER TABLE refresh_tokens
    ALTER COLUMN issued_at SET NOT NULL;

ALTER TABLE refresh_tokens
    ALTER COLUMN expires_at SET NOT NULL;

ALTER TABLE refresh_tokens
    ADD CONSTRAINT IF NOT EXISTS refresh_tokens_pkey PRIMARY KEY (refresh_token_id);

ALTER TABLE refresh_tokens
    ADD CONSTRAINT IF NOT EXISTS refresh_tokens_user_fk
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE refresh_tokens
    ADD CONSTRAINT IF NOT EXISTS refresh_tokens_token_hash_unique
        UNIQUE (token_hash);

CREATE UNIQUE INDEX IF NOT EXISTS idx_refresh_token_hash
    ON refresh_tokens (token_hash);

CREATE INDEX IF NOT EXISTS idx_refresh_token_user
    ON refresh_tokens (user_id);
