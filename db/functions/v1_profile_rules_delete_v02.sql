CREATE OR REPLACE FUNCTION v1_profile_rules_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE
    is_tailoring boolean;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM "profiles"
        WHERE "id" = OLD."profile_id"
        AND "parent_profile_id" IS NOT NULL
    ) INTO is_tailoring;

    IF is_tailoring THEN
        DELETE FROM "profile_rules" WHERE "id" = OLD."id";
    ELSE
        DELETE FROM "profile_rules_v2" WHERE "id" = OLD."id";
    END IF;

    RETURN OLD;
END
$func$;
