-- Ensure account_type primary key auto-increments even on existing databases
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_class WHERE relkind = 'S' AND relname = 'account_type_account_type_id_seq'
    ) THEN
        CREATE SEQUENCE account_type_account_type_id_seq;
        PERFORM setval('account_type_account_type_id_seq', COALESCE((SELECT max(account_type_id) FROM account_type), 0));
    END IF;

    ALTER TABLE account_type ALTER COLUMN account_type_id SET DEFAULT nextval('account_type_account_type_id_seq');
END $$;
