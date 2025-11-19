DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'mechanic_profiles' AND column_name = 'region'
    ) THEN
        ALTER TABLE mechanic_profiles ADD COLUMN region VARCHAR(255);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS mechanic_certifications (
    certification_id BIGSERIAL PRIMARY KEY,
    mechanic_profile_id BIGINT NOT NULL REFERENCES mechanic_profiles(profile_id) ON DELETE CASCADE,
    title VARCHAR(255),
    issuer VARCHAR(255),
    issue_date DATE,
    expiration_date DATE,
    credential_url VARCHAR(500),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mechanic_certifications_profile_id
    ON mechanic_certifications(mechanic_profile_id);

CREATE TABLE IF NOT EXISTS mechanic_work_history (
    history_id BIGSERIAL PRIMARY KEY,
    mechanic_profile_id BIGINT NOT NULL REFERENCES mechanic_profiles(profile_id) ON DELETE CASCADE,
    organization VARCHAR(255),
    position VARCHAR(255),
    start_date DATE,
    end_date DATE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mechanic_work_history_profile_id
    ON mechanic_work_history(mechanic_profile_id);

CREATE TABLE IF NOT EXISTS attestation_status_catalog (
    status_code VARCHAR(50) PRIMARY KEY,
    description TEXT
);

INSERT INTO attestation_status_catalog(status_code, description) VALUES
    ('NEW', 'Новая заявка'),
    ('IN_REVIEW', 'На рассмотрении'),
    ('APPROVED', 'Одобрена'),
    ('REJECTED', 'Отклонена')
ON CONFLICT (status_code) DO UPDATE SET description = EXCLUDED.description;

CREATE TABLE IF NOT EXISTS attestation_applications (
    application_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    mechanic_profile_id BIGINT REFERENCES mechanic_profiles(profile_id),
    club_id BIGINT REFERENCES bowling_clubs(club_id),
    status VARCHAR(50) NOT NULL REFERENCES attestation_status_catalog(status_code),
    comment TEXT,
    requested_grade VARCHAR(50),
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_attestation_applications_mechanic
    ON attestation_applications(mechanic_profile_id);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'parts_catalog' AND column_name = 'category_code'
    ) THEN
        ALTER TABLE parts_catalog ADD COLUMN category_code VARCHAR(100);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS personal_warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    mechanic_profile_id BIGINT NOT NULL REFERENCES mechanic_profiles(profile_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_personal_warehouses_profile_id
    ON personal_warehouses(mechanic_profile_id);
