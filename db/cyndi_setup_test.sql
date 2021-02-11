--
-- Intializes a Cyndi-like inventory schema and seeds it with sample data.
-- This script is intended to be used an extended for local development of applications against inventory schema.
-- Copied from https://github.com/RedHatInsights/inventory-syndication/blob/master/utils/seed-local.sql
--

CREATE SCHEMA IF NOT EXISTS inventory;

-- This table should never be queried direcly
CREATE TABLE inventory.hosts_v1_1 (
    id uuid PRIMARY KEY,
    account character varying(10) NOT NULL,
    display_name character varying(200) NOT NULL,
    tags jsonb NOT NULL,
    updated timestamp with time zone NOT NULL,
    created timestamp with time zone NOT NULL,
    stale_timestamp timestamp with time zone NOT NULL,
    system_profile jsonb NOT NULL
);

-- This view should be queried instead
CREATE OR REPLACE VIEW inventory.hosts AS
SELECT
    id,
    account,
    display_name,
    created,
    updated,
    stale_timestamp,
    stale_timestamp + INTERVAL '1' DAY * 7 AS stale_warning_timestamp,
    stale_timestamp + INTERVAL '1' DAY * 14 AS culled_timestamp,
    tags,
    system_profile
FROM inventory.hosts_v1_1;

--
-- These are the host seeds for use with testing locally and in CI
--
TRUNCATE inventory.hosts_v1_1;
INSERT INTO inventory.hosts_v1_1 VALUES ('5e65ac3f-8b44-4f60-9e99-abdafb31740c', '00001', 'MyStringone', '[{"namespace": "insights-client", "key": "env", "value": "prod"}]', '2020-07-21 05:35:53.682554+00', '2020-07-21 05:35:53.682554+00', '2030-07-21 05:35:53.682554+00', '{"sap_system": true, "operating_system": {"major": 7, "minor": 4, "name": "RHEL"}}');
INSERT INTO inventory.hosts_v1_1 VALUES ('328fb4c0-42fc-0139-06c0-6e70056f34f5', '00002', 'MyStringtwo', '[{"namespace": "insights-client", "key": "env", "value": "prod"}]', '2020-07-21 05:35:53.682554+00', '2020-07-21 05:35:53.682554+00', '2030-07-21 05:35:53.682554+00', '{"sap_system": true}');
