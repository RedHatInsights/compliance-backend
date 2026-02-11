SELECT
  "profile_rules_v2"."id",
  "profile_rules_v2"."profile_id",
  "profile_rules_v2"."rule_id",
  "profile_rules_v2"."created_at",
  "profile_rules_v2"."updated_at"
FROM "profile_rules_v2"

UNION ALL

SELECT
  "profile_rules"."id",
  "profile_rules"."profile_id",
  "profile_rules"."rule_id",
  "profile_rules"."created_at",
  "profile_rules"."updated_at"
FROM "profile_rules"
JOIN "profiles" ON "profile_rules"."profile_id" = "profiles"."id"
WHERE "profiles"."parent_profile_id" IS NOT NULL;
