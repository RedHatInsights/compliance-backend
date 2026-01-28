SELECT
  (ARRAY_AGG("canonical_profiles_v2"."id" ORDER BY STRING_TO_ARRAY("security_guides_v2"."version", '.')::int[] DESC))[1] AS "id",
  (ARRAY_AGG("canonical_profiles_v2"."title" ORDER BY STRING_TO_ARRAY("security_guides_v2"."version", '.')::int[] DESC))[1] AS "title",
  (ARRAY_AGG("canonical_profiles_v2"."description" ORDER BY STRING_TO_ARRAY("security_guides_v2"."version", '.')::int[] DESC))[1] AS "description",
  "canonical_profiles_v2"."ref_id" AS "ref_id",
  (ARRAY_AGG("security_guides_v2"."id" ORDER BY STRING_TO_ARRAY("security_guides_v2"."version", '.')::int[] DESC))[1] AS "security_guide_id",
  (ARRAY_AGG("security_guides_v2"."version" ORDER BY STRING_TO_ARRAY("security_guides_v2"."version", '.')::int[] DESC))[1] AS "security_guide_version",
  "security_guides_v2"."os_major_version" AS "os_major_version",
  ARRAY_AGG(DISTINCT "profile_os_minor_versions"."os_minor_version" ORDER BY "profile_os_minor_versions"."os_minor_version" DESC) AS "os_minor_versions"
FROM "canonical_profiles_v2"
INNER JOIN "security_guides_v2" ON "security_guides_v2"."id" = "canonical_profiles_v2"."security_guide_id"
INNER JOIN "profile_os_minor_versions" ON "profile_os_minor_versions"."profile_id" = "canonical_profiles_v2"."id"
GROUP BY "canonical_profiles_v2"."ref_id", "security_guides_v2"."os_major_version";

