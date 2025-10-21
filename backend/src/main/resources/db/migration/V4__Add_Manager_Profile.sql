CREATE TABLE IF NOT EXISTS manager_profiles (
    manager_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(user_id),
    club_id BIGINT,
    full_name VARCHAR(255),
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),
    is_data_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO role (name)
SELECT 'MANAGER'
WHERE NOT EXISTS (SELECT 1 FROM role WHERE UPPER(name) = 'MANAGER');

INSERT INTO account_type (name)
SELECT 'Менеджер'
WHERE NOT EXISTS (SELECT 1 FROM account_type WHERE UPPER(name) = UPPER('Менеджер'));
