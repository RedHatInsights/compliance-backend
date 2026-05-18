CREATE OR REPLACE FUNCTION v1_policy_hosts_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    DELETE FROM "policy_systems_v2" WHERE "id" = OLD."id";
    RETURN OLD;
END
$func$;
