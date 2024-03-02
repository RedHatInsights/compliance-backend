SELECT
  "v2_policies".*
FROM "v2_policies"
  INNER JOIN "tailorings" ON "tailorings"."policy_id" = "v2_policies"."id"
  INNER JOIN "test_results" ON "test_results"."profile_id" = "tailorings"."id"
GROUP BY
  "v2_policies"."id",
  "v2_policies"."title",
  "v2_policies"."description",
  "v2_policies"."compliance_threshold",
  "v2_policies"."business_objective",
  "v2_policies"."system_count",
  "v2_policies"."profile_id",
  "v2_policies"."account_id";
