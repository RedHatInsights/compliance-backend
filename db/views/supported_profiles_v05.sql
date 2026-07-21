SELECT
  (ARRAY_AGG("profiles"."id" ORDER BY STRING_TO_ARRAY("security_guides"."version", '.')::int[] DESC))[1] AS "id",
  (ARRAY_AGG("profiles"."title" ORDER BY STRING_TO_ARRAY("security_guides"."version", '.')::int[] DESC))[1] AS "title",
  (ARRAY_AGG("profiles"."description" ORDER BY STRING_TO_ARRAY("security_guides"."version", '.')::int[] DESC))[1] AS "description",
  "profiles"."ref_id" AS "ref_id",
  (ARRAY_AGG("security_guides"."id" ORDER BY STRING_TO_ARRAY("security_guides"."version", '.')::int[] DESC))[1] AS "security_guide_id",
  (ARRAY_AGG("security_guides"."version" ORDER BY STRING_TO_ARRAY("security_guides"."version", '.')::int[] DESC))[1] AS "security_guide_version",
  "security_guides"."os_major_version" AS "os_major_version",
  ARRAY_AGG(DISTINCT "profile_os_minor_versions"."os_minor_version" ORDER BY "profile_os_minor_versions"."os_minor_version" DESC) AS "os_minor_versions"
FROM "profiles"
INNER JOIN "security_guides" ON "security_guides"."id" = "profiles"."security_guide_id"
INNER JOIN "profile_os_minor_versions" ON "profile_os_minor_versions"."profile_id" = "profiles"."id"
GROUP BY "profiles"."ref_id", "security_guides"."os_major_version";
