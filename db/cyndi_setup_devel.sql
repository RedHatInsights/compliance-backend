--
-- Intializes a Cyndi-like inventory schema and creates a view copied from a
-- local inventory DB
--

CREATE SCHEMA IF NOT EXISTS inventory;

CREATE EXTENSION IF NOT EXISTS dblink;

-- This view should be queried instead
CREATE OR REPLACE VIEW inventory.hosts AS
SELECT
    id,
    account,
    org_id,
    display_name,
    created_on as created,
    modified_on as updated,
    stale_timestamp,
    stale_timestamp + INTERVAL '1' DAY * 7 AS stale_warning_timestamp,
    stale_timestamp + INTERVAL '1' DAY * 14 AS culled_timestamp,
    stale_timestamp + INTERVAL '1' DAY * 8 AS last_check_in,
    tags,
    jsonb_build_object('operating_system', operating_system, 'host_type', host_type, 'owner_id', owner_id) as system_profile,
    groups,
    insights_id
FROM dblink('dbname=insights user=insights', '
    SELECT h.id, h.account, h.org_id, h.display_name, h.created_on, h.modified_on,
           h.stale_timestamp, h.tags, h.groups, h.insights_id,
           sps.operating_system, sps.host_type, sps.owner_id
    FROM hbi.hosts h
    LEFT JOIN hbi.system_profiles_static sps ON sps.org_id = h.org_id AND sps.host_id = h.id
') as hosts(
    id uuid,
    account character varying(10),
    org_id character varying(10),
    display_name character varying(200),
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    stale_timestamp timestamp with time zone,
    tags jsonb,
    groups jsonb,
    insights_id uuid,
    operating_system jsonb,
    host_type character varying(12),
    owner_id character varying(64)
);
