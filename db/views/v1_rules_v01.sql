SELECT
  "rules_v2"."id",
  "rules_v2"."ref_id",
  NULL::boolean AS "supported",
  "rules_v2"."title",
  "rules_v2"."severity",
  "rules_v2"."description",
  "rules_v2"."rationale",
  "rules_v2"."created_at",
  "rules_v2"."updated_at",
  LOWER(REPLACE("rules_v2"."ref_id", '.', '-')) AS "slug",
  "rules_v2"."remediation_available",
  "rules_v2"."security_guide_id" AS "benchmark_id",
  "rules_v2"."upstream",
  "rules_v2"."precedence",
  "rules_v2"."rule_group_id",
  "rules_v2"."value_checks",
  "rules_v2"."identifier"
FROM "rules_v2";
