CREATE OR REPLACE FUNCTION v1_profile_rules_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE
    result_id uuid;
    is_tailoring boolean;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM "profiles"
        WHERE "id" = NEW."profile_id"
        AND "parent_profile_id" IS NOT NULL
    ) INTO is_tailoring;

    IF is_tailoring THEN
        INSERT INTO "profile_rules" (
          "profile_id",
          "rule_id",
          "created_at",
          "updated_at"
        ) VALUES (
          NEW."profile_id",
          NEW."rule_id",
          COALESCE(NEW."created_at", NOW()),
          COALESCE(NEW."updated_at", NOW())
        ) RETURNING "id" INTO "result_id";
    ELSE
        INSERT INTO "profile_rules_v2" (
          "profile_id",
          "rule_id",
          "created_at",
          "updated_at"
        ) VALUES (
          NEW."profile_id",
          NEW."rule_id",
          COALESCE(NEW."created_at", NOW()),
          COALESCE(NEW."updated_at", NOW())
        ) RETURNING "id" INTO "result_id";
    END IF;

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
