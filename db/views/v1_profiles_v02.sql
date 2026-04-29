SELECT
  "canonical_profiles_v2"."id",
  "canonical_profiles_v2"."title" AS "name",
  "canonical_profiles_v2"."ref_id",
  "canonical_profiles_v2"."created_at",
  "canonical_profiles_v2"."updated_at",
  "canonical_profiles_v2"."description",
  NULL::uuid AS "account_id",
  "canonical_profiles_v2"."security_guide_id" AS "benchmark_id",
  NULL::uuid AS "parent_profile_id",
  FALSE AS "external",
  NULL::uuid AS "policy_id",
  NULL::varchar AS "os_minor_version",
  NULL::decimal AS "score",
  "canonical_profiles_v2"."upstream",
  "canonical_profiles_v2"."value_overrides"
FROM "canonical_profiles_v2"

UNION ALL

SELECT
  "tailorings_v2"."id",
  "cp"."title" AS "name",
  "cp"."ref_id",
  "tailorings_v2"."created_at",
  "tailorings_v2"."updated_at",
  "cp"."description",
  "p"."account_id",
  "cp"."security_guide_id" AS "benchmark_id",
  "tailorings_v2"."profile_id" AS "parent_profile_id",
  FALSE AS "external",
  "tailorings_v2"."policy_id",
  CAST("tailorings_v2"."os_minor_version" AS varchar) AS "os_minor_version",
  NULL::decimal AS "score",
  FALSE AS "upstream",
  "tailorings_v2"."value_overrides"
FROM "tailorings_v2"
INNER JOIN "canonical_profiles_v2" "cp" ON "cp"."id" = "tailorings_v2"."profile_id"
INNER JOIN "policies_v2" "p" ON "p"."id" = "tailorings_v2"."policy_id";
