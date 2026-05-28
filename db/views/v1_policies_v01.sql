SELECT
  "policies_v2"."id",
  "policies_v2"."account_id",
  "business_objectives"."id" AS "business_objective_id",
  "policies_v2"."compliance_threshold",
  0 AS "compliant_host_count",
  "policies_v2"."description",
  "policies_v2"."title" AS "name",
  "policies_v2"."profile_id",
  0 AS "test_result_host_count",
  COALESCE("sq"."total_host_count", 0) AS "total_host_count",
  0 AS "unsupported_host_count"
FROM "policies_v2"
LEFT OUTER JOIN "business_objectives" ON "business_objectives"."title" = "policies_v2"."business_objective"
LEFT OUTER JOIN (
  SELECT COUNT("policy_systems_v2"."id") AS "total_host_count", "policy_systems_v2"."policy_id"
  FROM "policy_systems_v2" GROUP BY "policy_systems_v2"."policy_id"
) "sq" ON "sq"."policy_id" = "policies_v2"."id";
