DO $$
DECLARE
    seq_name text;
    max_user_id bigint;
BEGIN
    SELECT pg_get_serial_sequence('users', 'user_id') INTO seq_name;

    IF seq_name IS NULL THEN
        RETURN;
    END IF;

    SELECT COALESCE(MAX(user_id), 0) INTO max_user_id FROM users;

    PERFORM setval(seq_name, GREATEST(max_user_id, 54));
END;
$$;
