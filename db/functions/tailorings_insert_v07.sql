CREATE OR REPLACE FUNCTION tailorings_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
DECLARE external boolean;
BEGIN

-- Look up if there's at least one existing profile under this policy
-- and set the `external` flag to false or true accordingly
SELECT CASE WHEN COUNT("id") = 0 THEN FALSE ELSE TRUE END INTO "external"
FROM "profiles" WHERE "profiles"."policy_id" = NEW."policy_id" LIMIT 1;

INSERT INTO "profiles" (
  "name",
  "ref_id",
  "policy_id",
  "account_id",
  "parent_profile_id",
  "benchmark_id",
  "os_minor_version",
  "value_overrides",
  "external",
  "created_at",
  "updated_at"
) SELECT
  "canonical_profiles_v2"."title",
  "canonical_profiles_v2"."ref_id",
  NEW."policy_id",
  "policies"."account_id",
  NEW."profile_id",
  "canonical_profiles_v2"."security_guide_id",
  CAST(NEW."os_minor_version" AS text),
  NEW."value_overrides",
  "external",
  NEW."created_at",
  NEW."updated_at"
FROM "policies"
INNER JOIN "canonical_profiles_v2" ON "canonical_profiles_v2"."id" = "policies"."profile_id"
WHERE "policies"."id" = NEW."policy_id" RETURNING "id" INTO "result_id";

NEW."id" := "result_id";
RETURN NEW;

END
$func$;
