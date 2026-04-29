SELECT
  "historical_test_results_v2"."id",
  "historical_test_results_v2"."tailoring_id" AS "profile_id",
  "historical_test_results_v2"."system_id" AS "host_id",
  "historical_test_results_v2"."start_time",
  "historical_test_results_v2"."end_time",
  "historical_test_results_v2"."score",
  "historical_test_results_v2"."supported",
  "historical_test_results_v2"."failed_rule_count",
  "historical_test_results_v2"."created_at",
  "historical_test_results_v2"."updated_at"
FROM "historical_test_results_v2";
