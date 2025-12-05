-- Demonstration data for roles, account types, mechanics, clubs, warehouses, requests, and disputes.
-- Inserts only; no schema changes.

-- Ensure account types
INSERT INTO account_type (name) VALUES
    ('INDIVIDUAL'),
    ('CLUB_OWNER'),
    ('CLUB_MANAGER'),
    ('FREE_MECHANIC_BASIC'),
    ('FREE_MECHANIC_PREMIUM'),
    ('MAIN_ADMIN')
ON CONFLICT DO NOTHING;

-- Ensure access levels
INSERT INTO access_level (name) VALUES
    ('BASIC'),
    ('PREMIUM'),
    ('OWNER_MANAGER'),
    ('ADMIN')
ON CONFLICT DO NOTHING;

-- Ensure roles
INSERT INTO role (name) VALUES
    ('ADMIN'),
    ('MECHANIC'),
    ('HEAD_MECHANIC'),
    ('CLUB_OWNER')
ON CONFLICT DO NOTHING;

-- Seed clubs 1-6 if absent
INSERT INTO bowling_clubs (club_id, name, address, lanes_count, contact_phone, contact_email, is_active, is_verified, created_at, updated_at)
VALUES
    (1, 'Demo Club 1', 'Москва, ул. Ленина, 1', 10, '+74950000001', 'club1@demo.ru', true, true, CURRENT_DATE, CURRENT_DATE),
    (2, 'Demo Club 2', 'СПб, Невский пр., 2', 8, '+78120000002', 'club2@demo.ru', true, true, CURRENT_DATE, CURRENT_DATE),
    (3, 'Demo Club 3', 'Екатеринбург, ул. Мира, 3', 6, '+73430000003', 'club3@demo.ru', true, true, CURRENT_DATE, CURRENT_DATE),
    (4, 'Demo Club 4', 'Новосибирск, ул. Советская, 4', 12, '+73830000004', 'club4@demo.ru', true, true, CURRENT_DATE, CURRENT_DATE),
    (5, 'Demo Club 5', 'Казань, ул. Университетская, 5', 6, '+78430000005', 'club5@demo.ru', true, true, CURRENT_DATE, CURRENT_DATE),
    (6, 'Demo Club 6', 'Краснодар, ул. Северная, 6', 8, '+78610000006', 'club6@demo.ru', true, true, CURRENT_DATE, CURRENT_DATE)
ON CONFLICT DO NOTHING;

-- Basic parts catalog for request/warehouse examples
INSERT INTO parts_catalog (catalog_number, official_name_ru, official_name_en, common_name, description, normal_service_life, is_unique, category_code)
VALUES
    ('ZIP-100', 'Ролик подачи', 'Feed Roller', 'Ролик', 'Деталь подачи шара', 180, false, 'FEED'),
    ('ZIP-200', 'Датчик линии', 'Lane Sensor', 'Датчик', 'Оптический датчик дорожки', 365, false, 'SENSOR'),
    ('ZIP-300', 'Контроллер', 'Controller', 'Контроллер', 'Блок управления', 730, true, 'CTRL')
ON CONFLICT DO NOTHING;

-- Admin MAIN_ADMIN account with profile
WITH role_admin AS (
    SELECT role_id FROM role WHERE name = 'ADMIN' LIMIT 1
), acct_admin AS (
    SELECT account_type_id FROM account_type WHERE name = 'MAIN_ADMIN' LIMIT 1
), inserted AS (
    INSERT INTO users (password_hash, phone, role_id, registration_date, is_active, is_verified, account_type_id, last_modified)
    SELECT '$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79990000000', role_id, CURRENT_DATE, true, true, account_type_id, NOW()
    FROM role_admin, acct_admin
    ON CONFLICT DO NOTHING
    RETURNING user_id
)
INSERT INTO administrator_profiles (user_id, full_name, contact_phone, contact_email, is_data_verified, created_at, updated_at)
SELECT user_id, 'Главный Администратор', '+79990000000', 'admin@demo.ru', true, NOW(), NOW()
FROM inserted;

-- Free mechanic BASIC
WITH role_mech AS (SELECT role_id FROM role WHERE name = 'MECHANIC' LIMIT 1),
     acct_free_basic AS (SELECT account_type_id FROM account_type WHERE name = 'FREE_MECHANIC_BASIC' LIMIT 1),
     free_basic_user AS (
         INSERT INTO users (password_hash, phone, role_id, registration_date, is_active, is_verified, account_type_id, last_modified)
         SELECT '$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79995550101', role_id, CURRENT_DATE, true, true, account_type_id, NOW()
    FROM role_mech, acct_free_basic
    ON CONFLICT DO NOTHING
    RETURNING user_id
     ),
     free_basic_profile AS (
         INSERT INTO mechanic_profiles (user_id, full_name, birth_date, total_experience_years, bowling_experience_years, is_entrepreneur, skills, advantages, region, is_data_verified, verification_date, rating, created_at, updated_at)
         SELECT user_id, 'Свободный Базовый', DATE '1990-02-02', 5, 3, true, 'обслуживание дорожек', 'быстрая диагностика', 'Москва', true, CURRENT_DATE, 4.6, CURRENT_DATE, CURRENT_DATE
         FROM free_basic_user
         ON CONFLICT DO NOTHING
         RETURNING profile_id
     )
INSERT INTO personal_warehouses (name, location, is_active, created_at, updated_at, mechanic_profile_id)
SELECT 'Личный zip-склад Свободный Базовый', 'Москва, склад 1', true, NOW(), NOW(), profile_id
FROM free_basic_profile
ON CONFLICT DO NOTHING;

-- Free mechanic PREMIUM with warehouse inventory
WITH role_mech AS (SELECT role_id FROM role WHERE name = 'MECHANIC' LIMIT 1),
     acct_free_premium AS (SELECT account_type_id FROM account_type WHERE name = 'FREE_MECHANIC_PREMIUM' LIMIT 1),
     free_premium_user AS (
         INSERT INTO users (password_hash, phone, role_id, registration_date, is_active, is_verified, account_type_id, last_modified)
         SELECT '$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79995550202', role_id, CURRENT_DATE, true, true, account_type_id, NOW()
         FROM role_mech, acct_free_premium
         ON CONFLICT DO NOTHING
         RETURNING user_id
     ),
     free_premium_profile AS (
         INSERT INTO mechanic_profiles (user_id, full_name, birth_date, total_experience_years, bowling_experience_years, is_entrepreneur, skills, advantages, region, is_data_verified, verification_date, rating, created_at, updated_at)
         SELECT user_id, 'Свободный Премиум', DATE '1988-05-05', 8, 6, true, 'диагностика, настройка', 'расширенный опыт', 'Санкт-Петербург', true, CURRENT_DATE, 4.9, CURRENT_DATE, CURRENT_DATE
         FROM free_premium_user
         ON CONFLICT DO NOTHING
         RETURNING profile_id
     ),
     premium_warehouse AS (
         INSERT INTO personal_warehouses (name, location, is_active, created_at, updated_at, mechanic_profile_id)
         SELECT 'Личный zip-склад Свободный Премиум', 'СПб, склад 2', true, NOW(), NOW(), profile_id
         FROM free_premium_profile
         ON CONFLICT DO NOTHING
         RETURNING warehouse_id, mechanic_profile_id
     )
INSERT INTO warehouse_inventory (catalog_id, quantity, reserved_quantity, location_reference, warehouse_id, is_unique, placement_status, notes)
SELECT pc.catalog_id, 5, 1, 'ячейка А1', warehouse_id, pc.is_unique, 'ON_HAND', 'premium stock'
FROM premium_warehouse pw
JOIN parts_catalog pc ON pc.catalog_number = 'ZIP-200'
ON CONFLICT DO NOTHING;

-- Club mechanics and managers tied to clubs 1-6
WITH role_mech AS (SELECT role_id FROM role WHERE name = 'MECHANIC' LIMIT 1),
     role_head AS (SELECT role_id FROM role WHERE name = 'HEAD_MECHANIC' LIMIT 1),
     acct_ind AS (SELECT account_type_id FROM account_type WHERE name = 'INDIVIDUAL' LIMIT 1),
     acct_mgr AS (SELECT account_type_id FROM account_type WHERE name = 'CLUB_MANAGER' LIMIT 1)
INSERT INTO users (password_hash, phone, role_id, registration_date, is_active, is_verified, account_type_id, last_modified)
VALUES
    ('$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79994440101', (SELECT role_id FROM role_mech), CURRENT_DATE, true, true, (SELECT account_type_id FROM acct_ind), NOW()),
    ('$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79994440102', (SELECT role_id FROM role_mech), CURRENT_DATE, true, true, (SELECT account_type_id FROM acct_ind), NOW()),
    ('$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79994440103', (SELECT role_id FROM role_mech), CURRENT_DATE, true, true, (SELECT account_type_id FROM acct_ind), NOW()),
    ('$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79994440201', (SELECT role_id FROM role_head), CURRENT_DATE, true, true, (SELECT account_type_id FROM acct_mgr), NOW()),
    ('$2a$10$XURPShQNCsLjp1Qc2H4pzO8VzQ1UVlF4EwJ5J8d8X5gX5zJ5r5V6e', '+79994440202', (SELECT role_id FROM role_head), CURRENT_DATE, true, true, (SELECT account_type_id FROM acct_mgr), NOW())
ON CONFLICT DO NOTHING;

-- Mechanic profiles for club staff
WITH mech_users AS (
    SELECT u.user_id, u.phone,
           ROW_NUMBER() OVER (ORDER BY u.phone) AS rn
    FROM users u WHERE u.phone IN ('+79994440101','+79994440102','+79994440103')
),
prof AS (
    INSERT INTO mechanic_profiles (user_id, full_name, birth_date, total_experience_years, bowling_experience_years, is_entrepreneur, region, is_data_verified, verification_date, rating, created_at, updated_at)
    SELECT user_id,
           CASE WHEN rn = 1 THEN 'Клубный механик 1' WHEN rn = 2 THEN 'Клубный механик 2' ELSE 'Клубный механик 3' END,
           DATE '1991-01-01', 4 + rn, 2 + rn, false, 'Регион ' || rn, true, CURRENT_DATE, 4.0 + rn * 0.1, CURRENT_DATE, CURRENT_DATE
    FROM mech_users
    ON CONFLICT DO NOTHING
    RETURNING profile_id, user_id
)
INSERT INTO club_mechanics (mechanic_profile_id, club_id)
SELECT p.profile_id,
       CASE mu.rn WHEN 1 THEN 1 WHEN 2 THEN 2 ELSE 3 END
FROM prof p
JOIN mech_users mu ON mu.user_id = p.user_id
ON CONFLICT DO NOTHING;

-- Manager profiles bound to clubs
WITH mgr_users AS (
    SELECT u.user_id, u.phone,
           ROW_NUMBER() OVER (ORDER BY u.phone) AS rn
    FROM users u WHERE u.phone IN ('+79994440201','+79994440202')
),
manager_profiles AS (
    INSERT INTO manager_profiles (user_id, club_id, full_name, contact_phone, contact_email, is_data_verified, created_at, updated_at)
    SELECT user_id,
           CASE rn WHEN 1 THEN 4 ELSE 5 END,
           CASE rn WHEN 1 THEN 'Менеджер Клуба 4' ELSE 'Менеджер Клуба 5' END,
           phone,
           CASE rn WHEN 1 THEN 'manager4@demo.ru' ELSE 'manager5@demo.ru' END,
           true, NOW(), NOW()
    FROM mgr_users
    ON CONFLICT DO NOTHING
    RETURNING user_id, club_id
)
INSERT INTO club_staff (user_id, club_id, role_id, is_active, assigned_at, info_access_restricted)
SELECT mp.user_id, mp.club_id, (SELECT role_id FROM role WHERE name = 'HEAD_MECHANIC' LIMIT 1), true, NOW(), false
FROM manager_profiles mp
ON CONFLICT DO NOTHING;

-- Club staff entries for mechanics
INSERT INTO club_staff (user_id, club_id, role_id, is_active, assigned_at, info_access_restricted)
SELECT u.user_id, cm.club_id, (SELECT role_id FROM role WHERE name = 'MECHANIC' LIMIT 1), true, NOW(), false
FROM users u
JOIN mechanic_profiles mp ON mp.user_id = u.user_id
JOIN club_mechanics cm ON cm.mechanic_profile_id = mp.profile_id
WHERE u.phone IN ('+79994440101', '+79994440102', '+79994440103')
ON CONFLICT DO NOTHING;

-- Attestation applications with different statuses
INSERT INTO attestation_applications (user_id, mechanic_profile_id, club_id, status, comment, requested_grade, submitted_at, updated_at)
SELECT u.user_id, mp.profile_id, cm.club_id, s.status, s.comment, s.grade, NOW(), NOW()
FROM (
      VALUES ('+79995550101', 'APPROVED', 'Утверждено', 'MIDDLE'),
             ('+79994440101', 'PENDING', 'В обработке', 'JUNIOR'),
             ('+79995550202', 'REJECTED', 'Недостаточно опыта', 'SENIOR')
     ) AS s(phone, status, comment, grade)
JOIN users u ON u.phone = s.phone
LEFT JOIN mechanic_profiles mp ON mp.user_id = u.user_id
LEFT JOIN club_mechanics cm ON cm.mechanic_profile_id = mp.profile_id
ON CONFLICT DO NOTHING;

-- Maintenance requests with parts: available vs missing
WITH reqs AS (
    INSERT INTO maintenance_requests (club_id, lane_number, mechanic_id, request_date, status, request_reason, manager_notes)
    VALUES
        (1, 1, (SELECT profile_id FROM mechanic_profiles mp JOIN users u ON u.user_id = mp.user_id WHERE u.phone = '+79994440101' LIMIT 1), NOW(), 'OPEN', 'Плановая проверка', 'Тестовая заявка'),
        (NULL, 0, (SELECT profile_id FROM mechanic_profiles mp JOIN users u ON u.user_id = mp.user_id WHERE u.phone = '+79995550101' LIMIT 1), NOW(), 'OPEN', 'Замена датчика', 'Свободный агент'),
        (2, 3, (SELECT profile_id FROM mechanic_profiles mp JOIN users u ON u.user_id = mp.user_id WHERE u.phone = '+79995550202' LIMIT 1), NOW(), 'IN_PROGRESS', 'Требуется контроллер', 'Премиум агент')
    ON CONFLICT DO NOTHING
    RETURNING request_id, club_id
)
INSERT INTO request_parts (request_id, catalog_number, part_name, quantity, status, is_available, catalog_id, warehouse_id, inventory_id, inventory_location, help_requested)
VALUES
    ((SELECT request_id FROM reqs LIMIT 1), 'ZIP-100', 'Ролик подачи', 2, 'REQUESTED', true, (SELECT catalog_id FROM parts_catalog WHERE catalog_number='ZIP-100' LIMIT 1), (SELECT warehouse_id FROM club_staff cs JOIN bowling_clubs bc ON cs.club_id = bc.club_id WHERE cs.club_id =1 LIMIT 1), NULL, 'склад клуба', false),
    ((SELECT request_id FROM reqs OFFSET 1 LIMIT 1), 'ZIP-200', 'Датчик линии', 1, 'REQUESTED', false, (SELECT catalog_id FROM parts_catalog WHERE catalog_number='ZIP-200' LIMIT 1), NULL, NULL, NULL, true),
    ((SELECT request_id FROM reqs OFFSET 2 LIMIT 1), 'ZIP-300', 'Контроллер', 1, 'REQUESTED', true, (SELECT catalog_id FROM parts_catalog WHERE catalog_number='ZIP-300' LIMIT 1), NULL, NULL, NULL, false)
ON CONFLICT DO NOTHING;

-- Purchase orders demonstrating full and partial acceptance
WITH supp AS (
    INSERT INTO suppliers (inn, legal_name, contact_person, contact_phone, contact_email, rating, is_verified, created_at, updated_at)
    VALUES ('7700000001', 'ООО Поставщик 1', 'Иван', '+74950001111', 'supply1@demo.ru', 4.5, true, NOW(), NOW())
    ON CONFLICT (inn) DO UPDATE SET legal_name = EXCLUDED.legal_name
    RETURNING supplier_id
),
req AS (
    SELECT request_id FROM maintenance_requests ORDER BY request_id LIMIT 1
),
po AS (
    INSERT INTO purchase_orders (supplier_id, request_id, status, order_date, expected_delivery_date, actual_delivery_date)
    SELECT supplier_id, request_id, 'PARTIAL_ACCEPTANCE', NOW(), NOW() + INTERVAL '5 days', NOW()
    FROM supp, req
    ON CONFLICT DO NOTHING
    RETURNING order_id
)
UPDATE request_parts rp
SET order_id = (SELECT order_id FROM po),
    accepted_quantity = CASE WHEN rp.catalog_number='ZIP-100' THEN 1 ELSE 0 END,
    acceptance_date = NOW(),
    acceptance_comment = 'Частичная поставка',
    status = CASE WHEN rp.catalog_number='ZIP-100' THEN 'APPROVED' ELSE 'REJECTED' END
WHERE rp.request_id = (SELECT request_id FROM req);

-- Supplier reviews including complaint
WITH po AS (SELECT order_id, supplier_id FROM purchase_orders ORDER BY order_id DESC LIMIT 1),
     reviewer AS (SELECT user_id, club_id FROM users u LEFT JOIN club_staff cs ON cs.user_id = u.user_id WHERE u.phone = '+79994440201' LIMIT 1)
INSERT INTO supplier_reviews (supplier_id, club_id, user_id, order_id, rating, comment, review_date, is_complaint, complaint_status, complaint_title, complaint_resolved, resolution_notes)
VALUES
    ((SELECT supplier_id FROM po), (SELECT club_id FROM reviewer), (SELECT user_id FROM reviewer), (SELECT order_id FROM po), 5, 'Все ок', NOW(), false, NULL, NULL, false, NULL),
    ((SELECT supplier_id FROM po), (SELECT club_id FROM reviewer), (SELECT user_id FROM reviewer), (SELECT order_id FROM po), 2, 'Недопоставка', NOW(), true, 'OPEN', 'Претензия по количеству', false, 'Ожидает разбирательства')
ON CONFLICT DO NOTHING;

-- Service history for maintenance indicators
WITH mech AS (SELECT profile_id FROM mechanic_profiles mp JOIN users u ON u.user_id = mp.user_id WHERE u.phone = '+79994440102' LIMIT 1)
INSERT INTO service_history (club_id, mechanic_id, equipment_id, work_description, work_date, status)
VALUES
    (1, (SELECT profile_id FROM mech), NULL, 'Плановое ТО', CURRENT_DATE - INTERVAL '60 days', 'COMPLETED'),
    (2, (SELECT profile_id FROM mech), NULL, 'Замена датчика', CURRENT_DATE - INTERVAL '10 days', 'COMPLETED')
ON CONFLICT DO NOTHING;

INSERT INTO service_history_parts (service_history_id, catalog_id, quantity_used)
SELECT sh.service_history_id, pc.catalog_id, 1
FROM service_history sh
JOIN parts_catalog pc ON pc.catalog_number = 'ZIP-200'
ON CONFLICT DO NOTHING;
