SELECT
  "profiles"."id",
  "profiles"."name" "title",
  "profiles"."ref_id",
  "profiles"."created_at",
  "profiles"."updated_at",
  "profiles"."description",
  "profiles"."benchmark_id" AS "security_guide_id",
  "profiles"."upstream",
  "profiles"."value_overrides"
FROM "profiles" WHERE "profiles"."parent_profile_id" IS NULL;
