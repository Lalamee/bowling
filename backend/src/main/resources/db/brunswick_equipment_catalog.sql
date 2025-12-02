-- Brunswick equipment hierarchy seed script
-- Inserts brand, categories, and child lines/models for Brunswick equipment

-- Root brand
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active)
VALUES (1000, NULL, 1, 'Brunswick', 'Brunswick', 'Brunswick', 1, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Level 2: Brunswick main categories
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
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
    (1240, 1000, 2, 'Brunswick', 'Механика/кинематика', 'Mechanics & kinematics', 15, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Level 3: Pinsetter models
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1101, 1100, 3, 'Brunswick', 'Boost ST (стринг-кегли)', 'Boost ST (string pins)', 1, TRUE),
    (1102, 1100, 3, 'Brunswick', 'GS NXT', 'GS NXT', 2, TRUE),
    (1103, 1100, 3, 'Brunswick', 'GS-X', 'GS-X', 3, TRUE),
    (1104, 1100, 3, 'Brunswick', 'GS-98', 'GS-98', 4, TRUE),
    (1105, 1100, 3, 'Brunswick', 'GS-96', 'GS-96', 5, TRUE),
    (1106, 1100, 3, 'Brunswick', 'GS-92', 'GS-92', 6, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Level 3: Scoring & Management systems
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1111, 1110, 3, 'Brunswick', 'Sync Invicta / Sync Spark', 'Sync Invicta / Sync Spark', 1, TRUE),
    (1112, 1110, 3, 'Brunswick', 'Sync', 'Sync', 2, TRUE),
    (1113, 1110, 3, 'Brunswick', 'Vector Plus', 'Vector Plus', 3, TRUE),
    (1114, 1110, 3, 'Brunswick', 'Vector', 'Vector', 4, TRUE),
    (1115, 1110, 3, 'Brunswick', 'Frameworx', 'Frameworx', 5, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Level 3: Ball Return systems
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1121, 1120, 3, 'Brunswick', 'Framework Ball Return', 'Framework Ball Return', 1, TRUE),
    (1122, 1120, 3, 'Brunswick', 'Center Stage Ball Return', 'Center Stage Ball Return', 2, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Level 3: Lane parts groups
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1131, 1130, 3, 'Brunswick', 'Синтетическое покрытие', 'Synthetic lane surface', 1, TRUE),
    (1132, 1130, 3, 'Brunswick', 'Бамперы', 'Bumpers', 2, TRUE),
    (1133, 1130, 3, 'Brunswick', 'Кеппинги, фолл-линии', 'Capping, foul units', 3, TRUE),
    (1134, 1130, 3, 'Brunswick', 'Kickbacks, пиндеки, гаттеры', 'Kickbacks, pindecks, gutters', 4, TRUE),
    (1135, 1130, 3, 'Brunswick', 'Деревянная подоснова и прочее', 'Wood substructure & other', 5, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Level 3: Lane Machines models
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1141, 1140, 3, 'Brunswick', 'Phoenix Lite (LT4)', 'Phoenix Lite (LT4)', 1, TRUE),
    (1142, 1140, 3, 'Brunswick', 'NEXUS', 'NEXUS', 2, TRUE),
    (1143, 1140, 3, 'Brunswick', 'Envoy', 'Envoy', 3, TRUE),
    (1144, 1140, 3, 'Brunswick', 'Crossfire', 'Crossfire', 4, TRUE),
    (1145, 1140, 3, 'Brunswick', 'Другие (QubicaAMF, Kegel и др.)', 'Other (including QubicaAMF, Kegel)', 5, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Level 3: Electronics blocks
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1221, 1220, 3, 'Brunswick', 'Silver Box', 'Silver Box', 1, TRUE),
    (1222, 1220, 3, 'Brunswick', 'Red Box', 'Red Box', 2, TRUE),
    (1223, 1220, 3, 'Brunswick', 'Консолидированная и Nexgen электроника', 'Consolidated & Nexgen electronics', 3, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Level 3: Placeholder children for other categories
INSERT INTO public.equipment_category (id, parent_id, level, brand, name_ru, name_en, sort_order, is_active) VALUES
    (1151, 1150, 3, 'Brunswick', 'Мебель, фурнитура — прочее', 'Furniture & fixtures — other', 1, TRUE),
    (1161, 1160, 3, 'Brunswick', 'Расходники, про-шоп и уход за дорожками — прочее', 'Consumables & pro shop — other', 1, TRUE),
    (1171, 1170, 3, 'Brunswick', 'Прочее — прочие позиции', 'Miscellaneous — other items', 1, TRUE),
    (1181, 1180, 3, 'Brunswick', 'Шары — прочее', 'Balls — other', 1, TRUE),
    (1191, 1190, 3, 'Brunswick', 'Кегли — прочее', 'Pins — other', 1, TRUE),
    (1201, 1200, 3, 'Brunswick', 'Прокатная обувь — прочее', 'Rental shoes — other', 1, TRUE),
    (1211, 1210, 3, 'Brunswick', 'Средства для ухода за дорожками — прочее', 'Lane care products — other', 1, TRUE),
    (1231, 1230, 3, 'Brunswick', 'GS-модели — прочее', 'GS models — other', 1, TRUE),
    (1241, 1240, 3, 'Brunswick', 'Механика/кинематика — прочее', 'Mechanics & kinematics — other', 1, TRUE)
ON CONFLICT (id) DO NOTHING;
