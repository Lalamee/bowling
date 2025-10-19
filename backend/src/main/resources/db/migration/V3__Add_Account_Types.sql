-- Create account_type table if it doesn't exist
CREATE TABLE IF NOT EXISTS account_type (
    account_type_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- Insert account types if they don't exist
INSERT INTO account_type (name)
SELECT 'Владелец'
WHERE NOT EXISTS (SELECT 1 FROM account_type WHERE name = 'Владелец');

INSERT INTO account_type (name)
SELECT 'Механик'
WHERE NOT EXISTS (SELECT 1 FROM account_type WHERE name = 'Механик');

INSERT INTO account_type (name)
SELECT 'Главный механик'
WHERE NOT EXISTS (SELECT 1 FROM account_type WHERE name = 'Главный механик');

INSERT INTO account_type (name)
SELECT 'Администратор'
WHERE NOT EXISTS (SELECT 1 FROM account_type WHERE name = 'Администратор');

-- Add account_type_id column to users table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'account_type_id') THEN
        ALTER TABLE users 
        ADD COLUMN account_type_id BIGINT REFERENCES account_type(account_type_id);
    END IF;
END $$;

-- Update existing users with account types
UPDATE users u
SET account_type_id = at.account_type_id
FROM account_type at
WHERE 
    (u.phone = '+79001234567' AND at.name = 'Администратор') OR
    (u.phone = '+79011234567' AND at.name = 'Владелец') OR
    (u.phone = '+79011234568' AND at.name = 'Главный механик');

-- Make account_type_id not null after setting all existing users
ALTER TABLE users ALTER COLUMN account_type_id SET NOT NULL;
