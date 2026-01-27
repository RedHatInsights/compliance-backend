CREATE OR REPLACE FUNCTION v1_profiles_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    IF NEW."parent_profile_id" IS NULL THEN
        INSERT INTO "canonical_profiles_v2" (
          "title",
          "ref_id",
          "description",
          "security_guide_id",
          "upstream",
          "value_overrides",
          "created_at",
          "updated_at"
        ) VALUES (
          NEW."name",
          NEW."ref_id",
          NEW."description",
          NEW."benchmark_id",
          COALESCE(NEW."upstream", FALSE),
          COALESCE(NEW."value_overrides", '{}'),
          COALESCE(NEW."created_at", NOW()),
          COALESCE(NEW."updated_at", NOW())
        ) RETURNING "id" INTO "result_id";
    ELSE
        INSERT INTO "profiles" (
          "name",
          "ref_id",
          "description",
          "account_id",
          "benchmark_id",
          "parent_profile_id",
          "external",
          "policy_id",
          "os_minor_version",
          "score",
          "upstream",
          "value_overrides",
          "created_at",
          "updated_at"
        ) VALUES (
          NEW."name",
          NEW."ref_id",
          NEW."description",
          NEW."account_id",
          NEW."benchmark_id",
          NEW."parent_profile_id",
          COALESCE(NEW."external", FALSE),
          NEW."policy_id",
          COALESCE(NEW."os_minor_version", ''),
          NEW."score",
          COALESCE(NEW."upstream", FALSE),
          COALESCE(NEW."value_overrides", '{}'),
          COALESCE(NEW."created_at", NOW()),
          COALESCE(NEW."updated_at", NOW())
        ) RETURNING "id" INTO "result_id";
    END IF;

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
