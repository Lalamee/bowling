ALTER TABLE users
    ADD COLUMN IF NOT EXISTS email VARCHAR(320);

DROP INDEX IF EXISTS idx_users_phone;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users (email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_unique ON users (phone);
