CREATE TABLE IF NOT EXISTS administrator_profiles (
    administrator_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(user_id),
    club_id BIGINT REFERENCES bowling_clubs(club_id),
    full_name VARCHAR(255),
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),
    is_data_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO role (name)
SELECT 'ADMINISTRATOR'
WHERE NOT EXISTS (SELECT 1 FROM role WHERE UPPER(name) = 'ADMINISTRATOR');

INSERT INTO account_type (name)
SELECT 'Администратор'
WHERE NOT EXISTS (SELECT 1 FROM account_type WHERE UPPER(name) = UPPER('Администратор'));
