DO $$
DECLARE
    seq_name text;
    max_user_id bigint;
    max_mechanic_user_id bigint;
    target_floor bigint;
BEGIN
    SELECT pg_get_serial_sequence('users', 'user_id') INTO seq_name;

    IF seq_name IS NULL THEN
        RETURN;
    END IF;

    SELECT COALESCE(MAX(user_id), 0) INTO max_user_id FROM users;

    SELECT COALESCE(MAX(user_id), 0) INTO max_mechanic_user_id FROM mechanic_profiles;

    target_floor := GREATEST(max_user_id, max_mechanic_user_id, 54);

    PERFORM setval(seq_name, target_floor);
END;
$$;
