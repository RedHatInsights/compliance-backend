SELECT
  "profile_rules_v2"."id",
  "profile_rules_v2"."profile_id",
  "profile_rules_v2"."rule_id",
  "profile_rules_v2"."created_at",
  "profile_rules_v2"."updated_at"
FROM "profile_rules_v2"

UNION ALL

SELECT
  "tailoring_rules_v2"."id",
  "tailoring_rules_v2"."tailoring_id" AS "profile_id",
  "tailoring_rules_v2"."rule_id",
  "tailoring_rules_v2"."created_at",
  "tailoring_rules_v2"."updated_at"
FROM "tailoring_rules_v2";
