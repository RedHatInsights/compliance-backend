SELECT
  "rule_groups_v2"."id",
  "rule_groups_v2"."ref_id",
  "rule_groups_v2"."title",
  "rule_groups_v2"."description",
  "rule_groups_v2"."rationale",
  "rule_groups_v2"."ancestry",
  "rule_groups_v2"."security_guide_id" AS "benchmark_id",
  "rule_groups_v2"."rule_id",
  "rule_groups_v2"."precedence",
  "rule_groups_v2"."created_at",
  "rule_groups_v2"."updated_at"
FROM "rule_groups_v2";
