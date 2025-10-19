-- Create ENUM types
CREATE TYPE access_level AS ENUM ('READ', 'WRITE', 'ADMIN');
CREATE TYPE account_type AS ENUM ('OWNER', 'MECHANIC', 'ADMIN');
CREATE TYPE education_level AS ENUM ('SECONDARY', 'VOCATIONAL', 'HIGHER');
CREATE TYPE document_type AS ENUM ('PASSPORT', 'DRIVER_LICENSE', 'CERTIFICATE', 'OTHER');

-- Create tables
CREATE TABLE role (
    role_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    role_id BIGINT NOT NULL REFERENCES role(role_id),
    registration_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    account_type VARCHAR(20) NOT NULL,
    version BIGINT,
    last_modified TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bowling_club (
    club_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    owner_id BIGINT REFERENCES users(user_id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE equipment_type (
    equipment_type_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE manufacturer (
    manufacturer_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE club_equipment (
    equipment_id BIGSERIAL PRIMARY KEY,
    club_id BIGINT REFERENCES bowling_club(club_id),
    equipment_type_id BIGINT REFERENCES equipment_type(equipment_type_id),
    manufacturer_id BIGINT REFERENCES manufacturer(manufacturer_id),
    model VARCHAR(100) NOT NULL,
    serial_number VARCHAR(100),
    purchase_date DATE,
    warranty_until DATE,
    status VARCHAR(50) NOT NULL,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial data
-- Insert roles
INSERT INTO role (name) VALUES 
    ('ADMIN'),
    ('CLUB_OWNER'),
    ('MECHANIC'),
    ('STAFF');

-- Insert default admin user (password: admin123)
INSERT INTO users (password_hash, phone, role_id, registration_date, is_active, is_verified, account_type)
VALUES ('$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79001234567', 
       (SELECT role_id FROM role WHERE name = 'ADMIN'), 
       CURRENT_DATE, true, true, 'ADMIN');

-- Insert equipment types
INSERT INTO equipment_type (name, description) VALUES 
    ('Bowling Lane', 'Standard bowling lane equipment'),
    ('Pinsetter', 'Automatic pinsetting machine'),
    ('Ball Return', 'Ball return system'),
    ('Scoring System', 'Electronic scoring system'),
    ('Seating', 'Spectator and player seating');

-- Insert sample manufacturer
INSERT INTO manufacturer (name, contact_person, phone, email, address) 
VALUES ('Brunswick Bowling', 'John Smith', '+18001234567', 'sales@brunswickbowling.com', '123 Bowling St, USA');

-- Create indexes
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_club_equipment_club_id ON club_equipment(club_id);
CREATE INDEX idx_club_equipment_equipment_type_id ON club_equipment(equipment_type_id);
CREATE INDEX idx_club_equipment_manufacturer_id ON club_equipment(manufacturer_id);
