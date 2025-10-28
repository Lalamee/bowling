CREATE TABLE IF NOT EXISTS document_type (
    document_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS access_level (
    access_level_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS technical_documents (
    document_id BIGSERIAL PRIMARY KEY,
    club_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    document_type_id INTEGER REFERENCES document_type(document_type_id),
    manufacturer_id BIGINT REFERENCES manufacturer(manufacturer_id),
    equipment_model VARCHAR(255),
    language VARCHAR(50),
    file_name VARCHAR(255),
    file_size BIGINT,
    file_url TEXT,
    file_data BYTEA,
    upload_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_by BIGINT REFERENCES users(user_id),
    access_level_id INTEGER REFERENCES access_level(access_level_id)
);

CREATE INDEX IF NOT EXISTS idx_technical_documents_club_id ON technical_documents(club_id);

INSERT INTO document_type (name)
    VALUES ('Manual'), ('Instruction'), ('Certificate')
    ON CONFLICT (name) DO NOTHING;

INSERT INTO access_level (name)
    VALUES ('PUBLIC'), ('INTERNAL'), ('CONFIDENTIAL')
    ON CONFLICT (name) DO NOTHING;
