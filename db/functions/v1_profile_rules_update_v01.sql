CREATE OR REPLACE FUNCTION v1_profile_rules_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    UPDATE "profile_rules_v2" SET
      "profile_id" = NEW."profile_id",
      "rule_id" = NEW."rule_id",
      "updated_at" = COALESCE(NEW."updated_at", NOW())
    WHERE "id" = OLD."id";

    RETURN NEW;
END
$func$;
