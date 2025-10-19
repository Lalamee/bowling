-- Sample data for bowling clubs
INSERT INTO bowling_club (name, address, phone, email, owner_id, is_active)
VALUES 
    ('Strike Zone', '123 Bowling Ave, Moscow', '+74951234567', 'info@strikezone.ru', 1, true),
    ('Lucky Strike', '456 Pins St, St. Petersburg', '+78121234567', 'info@luckystrike.spb.ru', 1, true);

-- Sample club equipment
WITH club1 AS (SELECT club_id FROM bowling_club WHERE name = 'Strike Zone' LIMIT 1),
     lane_type AS (SELECT equipment_type_id FROM equipment_type WHERE name = 'Bowling Lane' LIMIT 1),
     pinsetter_type AS (SELECT equipment_type_id FROM equipment_type WHERE name = 'Pinsetter' LIMIT 1),
     manufacturer1 AS (SELECT manufacturer_id FROM manufacturer WHERE name = 'Brunswick Bowling' LIMIT 1)
INSERT INTO club_equipment 
    (club_id, equipment_type_id, manufacturer_id, model, serial_number, purchase_date, warranty_until, status, last_maintenance_date, next_maintenance_date)
VALUES 
    ((SELECT club_id FROM club1), (SELECT equipment_type_id FROM lane_type), (SELECT manufacturer_id FROM manufacturer1),
     'Pro Lane X', 'PLX-001', '2023-01-15', '2026-01-15', 'ACTIVE', '2023-12-01', '2024-01-15'),
    
    ((SELECT club_id FROM club1), (SELECT equipment_type_id FROM pinsetter_type), (SELECT manufacturer_id FROM manufacturer1),
     'PinSetter 2000', 'PS2K-045', '2023-02-20', '2026-02-20', 'ACTIVE', '2023-12-10', '2024-02-20');

-- Insert sample staff users (passwords are hashed 'password123')
WITH role_owner AS (SELECT role_id FROM role WHERE name = 'CLUB_OWNER' LIMIT 1),
     role_mechanic AS (SELECT role_id FROM role WHERE name = 'MECHANIC' LIMIT 1)
INSERT INTO users 
    (password_hash, phone, role_id, registration_date, is_active, is_verified, account_type)
VALUES 
    -- Club owner
    ('$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79011234567', 
     (SELECT role_id FROM role_owner), CURRENT_DATE, true, true, 'OWNER'),
    
    -- Mechanic
    ('$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79011234568', 
     (SELECT role_id FROM role_mechanic), CURRENT_DATE, true, true, 'MECHANIC');

-- Update club with owner
UPDATE bowling_club 
SET owner_id = (SELECT user_id FROM users WHERE phone = '+79011234567')
WHERE name = 'Strike Zone';

-- Create club staff assignments
CREATE TABLE IF NOT EXISTS club_staff (
    club_staff_id BIGSERIAL PRIMARY KEY,
    club_id BIGINT NOT NULL REFERENCES bowling_club(club_id),
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    position VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(club_id, user_id)
);

-- Assign staff to clubs
INSERT INTO club_staff (club_id, user_id, position, hire_date)
SELECT 
    (SELECT club_id FROM bowling_club WHERE name = 'Strike Zone' LIMIT 1),
    user_id,
    CASE 
        WHEN phone = '+79011234567' THEN 'Owner'
        WHEN phone = '+79011234568' THEN 'Head Mechanic'
    END,
    CURRENT_DATE
FROM users 
WHERE phone IN ('+79011234567', '+79011234568');

-- Create maintenance requests table
CREATE TABLE IF NOT EXISTS maintenance_request (
    request_id BIGSERIAL PRIMARY KEY,
    equipment_id BIGINT REFERENCES club_equipment(equipment_id),
    reported_by BIGINT REFERENCES users(user_id),
    assigned_to BIGINT REFERENCES users(user_id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'OPEN',
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_notes TEXT
);

-- Sample maintenance request
INSERT INTO maintenance_request 
    (equipment_id, reported_by, assigned_to, title, description, status, priority)
SELECT 
    (SELECT equipment_id FROM club_equipment WHERE model = 'PinSetter 2000' LIMIT 1),
    (SELECT user_id FROM users WHERE phone = '+79011234567'),
    (SELECT user_id FROM users WHERE phone = '+79011234568'),
    'PinSetter not resetting properly',
    'PinSetter is not resetting pins correctly on lanes 5 and 6. Sometimes leaves pins standing.',
    'IN_PROGRESS',
    'HIGH';

-- Create indexes for performance
CREATE INDEX idx_club_staff_club_id ON club_staff(club_id);
CREATE INDEX idx_club_staff_user_id ON club_staff(user_id);
CREATE INDEX idx_maintenance_request_equipment_id ON maintenance_request(equipment_id);
CREATE INDEX idx_maintenance_request_reported_by ON maintenance_request(reported_by);
CREATE INDEX idx_maintenance_request_assigned_to ON maintenance_request(assigned_to);
