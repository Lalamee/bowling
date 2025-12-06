-- Align attestation statuses with PENDING/APPROVED/REJECTED model
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attestation_status_catalog') THEN
        DELETE FROM attestation_status_catalog WHERE status_code IN ('NEW', 'IN_REVIEW');
        INSERT INTO attestation_status_catalog(status_code, description)
        VALUES ('PENDING', 'Заявка в обработке')
        ON CONFLICT (status_code) DO UPDATE SET description = EXCLUDED.description;
        UPDATE attestation_applications
        SET status = 'PENDING'
        WHERE status IN ('NEW', 'IN_REVIEW');
    END IF;
END $$;

-- Extend mechanic profile with certification flags
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'mechanic_profiles' AND column_name = 'is_certified'
    ) THEN
        ALTER TABLE mechanic_profiles ADD COLUMN is_certified BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'mechanic_profiles' AND column_name = 'certified_grade'
    ) THEN
        ALTER TABLE mechanic_profiles ADD COLUMN certified_grade VARCHAR(50);
    END IF;
END $$;
