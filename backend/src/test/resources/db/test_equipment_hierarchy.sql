DELETE FROM equipment_components;
DELETE FROM equipment_category;

-- Root brand
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1000, NULL, 1, 'Brunswick', 'Brunswick', 'Brunswick', 1, TRUE);

-- Level 2 categories
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1100, 1000, 2, 'Brunswick', 'Пинсеттеры', 'Pinsetter parts', 1, TRUE),
    (1110, 1000, 2, 'Brunswick', 'Скоринг-системы', 'Scoring & Management systems', 2, TRUE),
    (1120, 1000, 2, 'Brunswick', 'Системы возврата шара', 'Ball Returns parts', 3, TRUE),
    (1130, 1000, 2, 'Brunswick', 'Комплектующие дорожек', 'Lane parts', 4, TRUE),
    (1140, 1000, 2, 'Brunswick', 'Натричные машины', 'Lane Machines', 5, TRUE),
    (1150, 1000, 2, 'Brunswick', 'Мебель, фурнитура', 'Furniture & fixtures', 6, TRUE),
    (1160, 1000, 2, 'Brunswick', 'Расходники, про-шоп и уход за дорожками', 'Consumables & pro shop', 7, TRUE),
    (1170, 1000, 2, 'Brunswick', 'Прочее', 'Miscellaneous', 8, TRUE),
    (1180, 1000, 2, 'Brunswick', 'Шары', 'Balls', 9, TRUE),
    (1190, 1000, 2, 'Brunswick', 'Кегли', 'Pins', 10, TRUE),
    (1200, 1000, 2, 'Brunswick', 'Прокатная обувь', 'Rental shoes', 11, TRUE),
    (1210, 1000, 2, 'Brunswick', 'Средства для ухода за дорожками', 'Lane care products', 12, TRUE),
    (1220, 1000, 2, 'Brunswick', 'Электроника', 'Electronics', 13, TRUE),
    (1230, 1000, 2, 'Brunswick', 'GS-модели', 'GS models', 14, TRUE),
    (1240, 1000, 2, 'Brunswick', 'Механика/кинематика', 'Mechanics & kinematics', 15, TRUE);

INSERT INTO equipment_components (component_id, category, code, manufacturer, name, notes, parent_id) VALUES
    (1000, 'Brand', 'BRUNSWICK', 'Brunswick', 'Brunswick', NULL, NULL),
    (1100, 'Pinsetter parts', 'PINSETTER_PARTS', 'Brunswick', 'Пинсеттеры', NULL, 1000),
    (1110, 'Scoring & Management systems', 'SCORING_SYSTEMS', 'Brunswick', 'Скоринг-системы', NULL, 1000),
    (1120, 'Ball Returns parts', 'BALL_RETURN', 'Brunswick', 'Системы возврата шара', NULL, 1000),
    (1130, 'Lane parts', 'LANE_PARTS', 'Brunswick', 'Комплектующие дорожек', NULL, 1000),
    (1140, 'Lane Machines', 'LANE_MACHINES', 'Brunswick', 'Натричные машины', NULL, 1000),
    (1150, 'Furniture & fixtures', 'FURNITURE', 'Brunswick', 'Мебель, фурнитура', NULL, 1000),
    (1160, 'Consumables & pro shop', 'CONSUMABLES', 'Brunswick', 'Расходники, про-шоп и уход за дорожками', NULL, 1000),
    (1170, 'Miscellaneous', 'MISC', 'Brunswick', 'Прочее', NULL, 1000),
    (1180, 'Balls', 'BALLS', 'Brunswick', 'Шары', NULL, 1000),
    (1190, 'Pins', 'PINS', 'Brunswick', 'Кегли', NULL, 1000),
    (1200, 'Rental shoes', 'RENTAL_SHOES', 'Brunswick', 'Прокатная обувь', NULL, 1000),
    (1210, 'Lane care products', 'LANE_CARE', 'Brunswick', 'Средства для ухода за дорожками', NULL, 1000),
    (1220, 'Electronics', 'ELECTRONICS', 'Brunswick', 'Электроника', NULL, 1000),
    (1230, 'GS models', 'GS_MODELS', 'Brunswick', 'GS-модели', NULL, 1000),
    (1240, 'Mechanics & kinematics', 'MECHANICS', 'Brunswick', 'Механика/кинематика', NULL, 1000),
    (1101, 'Pinsetter model', 'BOOST_ST', 'Brunswick', 'Boost ST (стринг-кегли)', NULL, 1100),
    (1102, 'Pinsetter model', 'GS_NXT', 'Brunswick', 'GS NXT', NULL, 1100),
    (1103, 'Pinsetter model', 'GS_X', 'Brunswick', 'GS-X', NULL, 1100),
    (1104, 'Pinsetter model', 'GS_98', 'Brunswick', 'GS-98', NULL, 1100),
    (1105, 'Pinsetter model', 'GS_96', 'Brunswick', 'GS-96', NULL, 1100),
    (1106, 'Pinsetter model', 'GS_92', 'Brunswick', 'GS-92', NULL, 1100),
    (1111, 'Scoring system', 'SYNC_INVICTA', 'Brunswick', 'Sync Invicta / Sync Spark', NULL, 1110),
    (1112, 'Scoring system', 'SYNC', 'Brunswick', 'Sync', NULL, 1110),
    (1113, 'Scoring system', 'VECTOR_PLUS', 'Brunswick', 'Vector Plus', NULL, 1110),
    (1114, 'Scoring system', 'VECTOR', 'Brunswick', 'Vector', NULL, 1110),
    (1115, 'Scoring system', 'FRAMEWORX', 'Brunswick', 'Frameworx', NULL, 1110),
    (1121, 'Ball return', 'FRAMEWORK_RETURN', 'Brunswick', 'Framework Ball Return', NULL, 1120),
    (1122, 'Ball return', 'CENTER_STAGE_RETURN', 'Brunswick', 'Center Stage Ball Return', NULL, 1120),
    (1131, 'Lane part', 'SYNTHETIC_SURFACE', 'Brunswick', 'Синтетическое покрытие', NULL, 1130),
    (1132, 'Lane part', 'BUMPERS', 'Brunswick', 'Бамперы', NULL, 1130),
    (1133, 'Lane part', 'CAPPING', 'Brunswick', 'Кеппинги, фолл-линии', NULL, 1130),
    (1134, 'Lane part', 'KICKBACKS', 'Brunswick', 'Kickbacks, пиндеки, гаттеры', NULL, 1130),
    (1135, 'Lane part', 'WOOD_BASE', 'Brunswick', 'Деревянная подоснова и прочее', NULL, 1130),
    (1141, 'Lane machine', 'PHOENIX_LITE', 'Brunswick', 'Phoenix Lite (LT4)', NULL, 1140),
    (1142, 'Lane machine', 'NEXUS', 'Brunswick', 'NEXUS', NULL, 1140),
    (1143, 'Lane machine', 'ENVOY', 'Brunswick', 'Envoy', NULL, 1140),
    (1144, 'Lane machine', 'CROSSFIRE', 'Brunswick', 'Crossfire', NULL, 1140),
    (1145, 'Lane machine', 'OTHER_LANE_MACHINES', 'Brunswick', 'Другие (QubicaAMF, Kegel и др.)', NULL, 1140),
    (1221, 'Electronics', 'SILVER_BOX', 'Brunswick', 'Silver Box', NULL, 1220),
    (1222, 'Electronics', 'RED_BOX', 'Brunswick', 'Red Box', NULL, 1220),
    (1223, 'Electronics', 'CONSOLIDATED', 'Brunswick', 'Консолидированная и Nexgen электроника', NULL, 1220),
    (1151, 'Furniture & fixtures — other', 'FURNITURE_OTHER', 'Brunswick', 'Мебель, фурнитура — прочее', NULL, 1150),
    (1161, 'Consumables & pro shop — other', 'CONSUMABLES_OTHER', 'Brunswick', 'Расходники, про-шоп и уход за дорожками — прочее', NULL, 1160),
    (1171, 'Miscellaneous — other items', 'MISC_OTHER', 'Brunswick', 'Прочее — прочие позиции', NULL, 1170),
    (1181, 'Balls — other', 'BALLS_OTHER', 'Brunswick', 'Шары — прочее', NULL, 1180),
    (1191, 'Pins — other', 'PINS_OTHER', 'Brunswick', 'Кегли — прочее', NULL, 1190),
    (1201, 'Rental shoes — other', 'RENTAL_SHOES_OTHER', 'Brunswick', 'Прокатная обувь — прочее', NULL, 1200),
    (1211, 'Lane care products — other', 'LANE_CARE_OTHER', 'Brunswick', 'Средства для ухода за дорожками — прочее', NULL, 1210),
    (1231, 'GS models — other', 'GS_MODELS_OTHER', 'Brunswick', 'GS-модели — прочее', NULL, 1230),
    (1241, 'Mechanics & kinematics — other', 'MECHANICS_OTHER', 'Brunswick', 'Механика/кинематика — прочее', NULL, 1240);

-- Pinsetter models
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1101, 1100, 3, 'Brunswick', 'Boost ST (стринг-кегли)', 'Boost ST (string pins)', 1, TRUE),
    (1102, 1100, 3, 'Brunswick', 'GS NXT', 'GS NXT', 2, TRUE),
    (1103, 1100, 3, 'Brunswick', 'GS-X', 'GS-X', 3, TRUE),
    (1104, 1100, 3, 'Brunswick', 'GS-98', 'GS-98', 4, TRUE),
    (1105, 1100, 3, 'Brunswick', 'GS-96', 'GS-96', 5, TRUE),
    (1106, 1100, 3, 'Brunswick', 'GS-92', 'GS-92', 6, TRUE);

-- Scoring systems
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1111, 1110, 3, 'Brunswick', 'Sync Invicta / Sync Spark', 'Sync Invicta / Sync Spark', 1, TRUE),
    (1112, 1110, 3, 'Brunswick', 'Sync', 'Sync', 2, TRUE),
    (1113, 1110, 3, 'Brunswick', 'Vector Plus', 'Vector Plus', 3, TRUE),
    (1114, 1110, 3, 'Brunswick', 'Vector', 'Vector', 4, TRUE),
    (1115, 1110, 3, 'Brunswick', 'Frameworx', 'Frameworx', 5, TRUE);

-- Ball returns
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1121, 1120, 3, 'Brunswick', 'Framework Ball Return', 'Framework Ball Return', 1, TRUE),
    (1122, 1120, 3, 'Brunswick', 'Center Stage Ball Return', 'Center Stage Ball Return', 2, TRUE);

-- Lane parts groups
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1131, 1130, 3, 'Brunswick', 'Синтетическое покрытие', 'Synthetic lane surface', 1, TRUE),
    (1132, 1130, 3, 'Brunswick', 'Бамперы', 'Bumpers', 2, TRUE),
    (1133, 1130, 3, 'Brunswick', 'Кеппинги, фолл-линии', 'Capping, foul units', 3, TRUE),
    (1134, 1130, 3, 'Brunswick', 'Kickbacks, пиндеки, гаттеры', 'Kickbacks, pindecks, gutters', 4, TRUE),
    (1135, 1130, 3, 'Brunswick', 'Деревянная подоснова и прочее', 'Wood substructure & other', 5, TRUE);

-- Lane machines
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1141, 1140, 3, 'Brunswick', 'Phoenix Lite (LT4)', 'Phoenix Lite (LT4)', 1, TRUE),
    (1142, 1140, 3, 'Brunswick', 'NEXUS', 'NEXUS', 2, TRUE),
    (1143, 1140, 3, 'Brunswick', 'Envoy', 'Envoy', 3, TRUE),
    (1144, 1140, 3, 'Brunswick', 'Crossfire', 'Crossfire', 4, TRUE),
    (1145, 1140, 3, 'Brunswick', 'Другие (QubicaAMF, Kegel и др.)', 'Other (including QubicaAMF, Kegel)', 5, TRUE);

-- Electronics
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1221, 1220, 3, 'Brunswick', 'Silver Box', 'Silver Box', 1, TRUE),
    (1222, 1220, 3, 'Brunswick', 'Red Box', 'Red Box', 2, TRUE),
    (1223, 1220, 3, 'Brunswick', 'Консолидированная и Nexgen электроника', 'Consolidated & Nexgen electronics', 3, TRUE);

-- Placeholder third level nodes
INSERT INTO equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1151, 1150, 3, 'Brunswick', 'Мебель, фурнитура — прочее', 'Furniture & fixtures — other', 1, TRUE),
    (1161, 1160, 3, 'Brunswick', 'Расходники, про-шоп и уход за дорожками — прочее', 'Consumables & pro shop — other', 1, TRUE),
    (1171, 1170, 3, 'Brunswick', 'Прочее — прочие позиции', 'Miscellaneous — other items', 1, TRUE),
    (1181, 1180, 3, 'Brunswick', 'Шары — прочее', 'Balls — other', 1, TRUE),
    (1191, 1190, 3, 'Brunswick', 'Кегли — прочее', 'Pins — other', 1, TRUE),
    (1201, 1200, 3, 'Brunswick', 'Прокатная обувь — прочее', 'Rental shoes — other', 1, TRUE),
    (1211, 1210, 3, 'Brunswick', 'Средства для ухода за дорожками — прочее', 'Lane care products — other', 1, TRUE),
    (1231, 1230, 3, 'Brunswick', 'GS-модели — прочее', 'GS models — other', 1, TRUE),
    (1241, 1240, 3, 'Brunswick', 'Механика/кинематика — прочее', 'Mechanics & kinematics — other', 1, TRUE);
