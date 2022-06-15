--
-- Intializes a Cyndi-like inventory schema and seeds it with sample data.
-- This script is intended to be used an extended for local development of applications against inventory schema.
-- Copied from https://github.com/RedHatInsights/inventory-syndication/blob/master/utils/seed-local.sql
--

CREATE SCHEMA IF NOT EXISTS inventory;

-- This table should never be queried direcly
DROP TABLE IF EXISTS inventory.hosts_v1_1 CASCADE;

CREATE TABLE inventory.hosts_v1_1 (
    id uuid PRIMARY KEY,
    account character varying(10) NOT NULL,
    org_id character varying(10) NOT NULL,
    display_name character varying(200) NOT NULL,
    tags jsonb NOT NULL,
    updated timestamp with time zone NOT NULL,
    created timestamp with time zone NOT NULL,
    stale_timestamp timestamp with time zone NOT NULL,
    system_profile jsonb NOT NULL,
    insights_id uuid
);

-- This view should be queried instead
CREATE OR REPLACE VIEW inventory.hosts AS
SELECT
    id,
    account,
    org_id,
    display_name,
    created,
    updated,
    stale_timestamp,
    stale_timestamp + INTERVAL '1' DAY * 7 AS stale_warning_timestamp,
    stale_timestamp + INTERVAL '1' DAY * 14 AS culled_timestamp,
    tags,
    system_profile,
    insights_id
FROM inventory.hosts_v1_1;

--
-- Clear any existing host seeds
--
TRUNCATE inventory.hosts_v1_1;
