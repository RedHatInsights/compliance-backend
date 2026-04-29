CREATE OR REPLACE FUNCTION v1_profile_rules_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE
    is_tailoring boolean;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM "tailorings_v2"
        WHERE "id" = NEW."profile_id"
    ) INTO is_tailoring;

    IF is_tailoring THEN
        UPDATE "tailoring_rules_v2" SET
          "tailoring_id" = NEW."profile_id",
          "rule_id" = NEW."rule_id",
          "updated_at" = COALESCE(NEW."updated_at", NOW())
        WHERE "id" = OLD."id";
    ELSE
        UPDATE "profile_rules_v2" SET
          "profile_id" = NEW."profile_id",
          "rule_id" = NEW."rule_id",
          "updated_at" = COALESCE(NEW."updated_at", NOW())
        WHERE "id" = OLD."id";
    END IF;

    RETURN NEW;
END
$func$;
