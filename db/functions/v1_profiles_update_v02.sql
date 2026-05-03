CREATE OR REPLACE FUNCTION v1_profiles_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    IF OLD."parent_profile_id" IS NULL THEN
        UPDATE "canonical_profiles_v2" SET
          "title" = NEW."name",
          "ref_id" = NEW."ref_id",
          "description" = NEW."description",
          "security_guide_id" = NEW."benchmark_id",
          "upstream" = COALESCE(NEW."upstream", FALSE),
          "value_overrides" = COALESCE(NEW."value_overrides", '{}'),
          "updated_at" = COALESCE(NEW."updated_at", NOW())
        WHERE "id" = OLD."id";
    ELSE
        UPDATE "tailorings_v2" SET
          "policy_id" = NEW."policy_id",
          "profile_id" = NEW."parent_profile_id",
          "value_overrides" = COALESCE(NEW."value_overrides", '{}'),
          "os_minor_version" = COALESCE(CAST(NULLIF(NEW."os_minor_version", '') AS int), 0),
          "updated_at" = COALESCE(NEW."updated_at", NOW())
        WHERE "id" = OLD."id";
    END IF;

    RETURN NEW;
END
$func$;
