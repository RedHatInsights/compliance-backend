SELECT
  "policies"."id",
  "policies"."name" AS "title",
  "policies"."description",
  "policies"."compliance_threshold",
  "business_objectives"."title" AS "business_objective",
  COALESCE("sq"."host_count", 0) AS "host_count",
  "policies"."profile_id",
  "policies"."account_id"
FROM "policies"
  LEFT OUTER JOIN "business_objectives" ON "business_objectives"."id" = "policies"."business_objective_id"
  LEFT OUTER JOIN (
    SELECT COUNT("policy_hosts"."host_id") AS "host_count", "policy_hosts"."policy_id" FROM "policy_hosts" GROUP BY "policy_hosts"."policy_id"
  ) "sq" ON "sq"."policy_id" = "policies"."id";
