SELECT
  "rules"."id",
  "rules"."ref_id",
  "rules"."supported",
  "rules"."title",
  "rules"."severity",
  "rules"."description",
  "rules"."rationale",
  "rules"."created_at",
  "rules"."updated_at",
  "rules"."slug",
  "rules"."remediation_available",
  "rules"."benchmark_id" AS "security_guide_id",
  "rules"."upstream",
  "rules"."precedence",
  "rules"."rule_group_id",
  "rules"."value_checks",
  "rules"."identifier"
FROM "rules";
