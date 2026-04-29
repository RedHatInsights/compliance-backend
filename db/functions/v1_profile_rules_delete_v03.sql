CREATE OR REPLACE FUNCTION v1_profile_rules_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE
    is_tailoring boolean;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM "tailorings_v2"
        WHERE "id" = OLD."profile_id"
    ) INTO is_tailoring;

    IF is_tailoring THEN
        DELETE FROM "tailoring_rules_v2" WHERE "id" = OLD."id";
    ELSE
        DELETE FROM "profile_rules_v2" WHERE "id" = OLD."id";
    END IF;

    RETURN OLD;
END
$func$;
