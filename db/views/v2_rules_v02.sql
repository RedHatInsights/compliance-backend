SELECT
  "rules"."id",
  "rules"."ref_id",
  "rules"."title",
  "rules"."severity",
  "rules"."description",
  "rules"."rationale",
  "rules"."created_at",
  "rules"."updated_at",
  "rules"."remediation_available",
  "rules"."benchmark_id" AS "security_guide_id",
  "rules"."upstream",
  "rules"."precedence",
  "rules"."rule_group_id",
  "rules"."value_checks",
  "rules"."identifier",
  "rule_references_containers"."rule_references" AS "references"
FROM "rules" LEFT OUTER JOIN "rule_references_containers" ON "rule_references_containers"."rule_id" = "rules"."id";
