SELECT
  "rule_results_v2"."id",
  "historical_test_results_v2"."system_id" AS "host_id",
  "rule_results_v2"."result",
  "rule_results_v2"."rule_id",
  "rule_results_v2"."test_result_id",
  "rule_results_v2"."created_at",
  "rule_results_v2"."updated_at"
FROM "rule_results_v2"
INNER JOIN "historical_test_results_v2" ON "historical_test_results_v2"."id" = "rule_results_v2"."test_result_id";
