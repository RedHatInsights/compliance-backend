SELECT
  "historical_test_results_v2"."id",
  "historical_test_results_v2"."tailoring_id",
  "historical_test_results_v2"."report_id",
  "historical_test_results_v2"."system_id",
  "historical_test_results_v2"."start_time",
  "historical_test_results_v2"."end_time",
  "historical_test_results_v2"."score",
  "historical_test_results_v2"."supported",
  "historical_test_results_v2"."failed_rule_count",
  "historical_test_results_v2"."created_at",
  "historical_test_results_v2"."updated_at"
FROM "historical_test_results_v2"
INNER JOIN (
  SELECT "historical_test_results_v2"."tailoring_id", "historical_test_results_v2"."system_id", MAX("historical_test_results_v2"."end_time") AS "end_time"
  FROM "historical_test_results_v2" GROUP BY "historical_test_results_v2"."tailoring_id", "historical_test_results_v2"."system_id"
) AS "tr" ON "historical_test_results_v2"."tailoring_id" = "tr"."tailoring_id" AND
             "historical_test_results_v2"."system_id" = "tr"."system_id" AND
             "historical_test_results_v2"."end_time" = "tr"."end_time";
