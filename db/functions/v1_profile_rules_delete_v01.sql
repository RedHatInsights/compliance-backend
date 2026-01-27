CREATE OR REPLACE FUNCTION v1_profile_rules_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    DELETE FROM "profile_rules_v2" WHERE "id" = OLD."id";
    RETURN OLD;
END
$func$;
