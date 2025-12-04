-- ---------------------------------------------------------------------------
-- Database schema for the Customer Sync application
-- This script is executed automatically by the official Postgres image
-- on container start (mounted into /docker-entrypoint-initdb.d).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS customers (
    id            BIGSERIAL PRIMARY KEY,
    first_name    VARCHAR(100)    NOT NULL,
    last_name     VARCHAR(100)    NOT NULL,
    email         VARCHAR(255)    NOT NULL UNIQUE,
    created_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    synced_to_crm BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_customers_synced_to_crm
    ON customers (synced_to_crm);

CREATE INDEX IF NOT EXISTS idx_customers_created_at
    ON customers (created_at);
