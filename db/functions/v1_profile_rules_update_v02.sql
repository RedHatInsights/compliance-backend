CREATE OR REPLACE FUNCTION v1_profile_rules_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE
    is_tailoring boolean;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM "profiles"
        WHERE "id" = NEW."profile_id"
        AND "parent_profile_id" IS NOT NULL
    ) INTO is_tailoring;

    IF is_tailoring THEN
        UPDATE "profile_rules" SET
          "profile_id" = NEW."profile_id",
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
