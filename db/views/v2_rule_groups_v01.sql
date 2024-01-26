SELECT
  "rule_groups"."id",
  "rule_groups"."ref_id",
  "rule_groups"."title",
  "rule_groups"."description",
  "rule_groups"."rationale",
  "rule_groups"."ancestry",
  "rule_groups"."benchmark_id" AS "security_guide_id",
  "rule_groups"."rule_id",
  "rule_groups"."precedence"
FROM "rule_groups";
