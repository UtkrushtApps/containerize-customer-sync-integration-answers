-- ---------------------------------------------------------------------------
-- Seed data for local development / demos
-- ---------------------------------------------------------------------------

INSERT INTO customers (first_name, last_name, email, synced_to_crm)
VALUES
    ('Alice',   'Anderson', 'alice.anderson@example.com',   FALSE),
    ('Bob',     'Brown',    'bob.brown@example.com',        FALSE),
    ('Charlie', 'Clark',    'charlie.clark@example.com',    FALSE),
    ('Diana',   'Dawson',   'diana.dawson@example.com',     FALSE)
ON CONFLICT (email) DO NOTHING;
