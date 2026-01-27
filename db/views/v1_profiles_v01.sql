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

-- Tailorings (parent_profile_id IS NOT NULL)
SELECT
  "profiles"."id",
  "profiles"."name",
  "profiles"."ref_id",
  "profiles"."created_at",
  "profiles"."updated_at",
  "profiles"."description",
  "profiles"."account_id",
  "profiles"."benchmark_id",
  "profiles"."parent_profile_id",
  "profiles"."external",
  "profiles"."policy_id",
  "profiles"."os_minor_version",
  "profiles"."score",
  "profiles"."upstream",
  "profiles"."value_overrides"
FROM "profiles"
WHERE "profiles"."parent_profile_id" IS NOT NULL;
