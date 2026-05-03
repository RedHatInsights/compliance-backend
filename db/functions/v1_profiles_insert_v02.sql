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
        INSERT INTO "tailorings_v2" (
          "policy_id",
          "profile_id",
          "value_overrides",
          "os_minor_version",
          "created_at",
          "updated_at"
        ) VALUES (
          NEW."policy_id",
          NEW."parent_profile_id",
          COALESCE(NEW."value_overrides", '{}'),
          COALESCE(CAST(NULLIF(NEW."os_minor_version", '') AS int), 0),
          COALESCE(NEW."created_at", NOW()),
          COALESCE(NEW."updated_at", NOW())
        ) RETURNING "id" INTO "result_id";
    END IF;

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
