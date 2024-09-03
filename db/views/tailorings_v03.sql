SELECT
  "profiles"."id",
  "profiles"."policy_id",
  "profiles"."parent_profile_id" AS "profile_id",
  "profiles"."value_overrides",
  CAST(NULLIF("profiles"."os_minor_version", '') AS int) AS "os_minor_version",
  "profiles"."created_at",
  "profiles"."updated_at"
FROM "profiles" WHERE "profiles"."parent_profile_id" IS NOT NULL;
