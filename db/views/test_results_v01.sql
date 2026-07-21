SELECT
  "historical_test_results"."id",
  "historical_test_results"."tailoring_id",
  "historical_test_results"."report_id",
  "historical_test_results"."system_id",
  "historical_test_results"."start_time",
  "historical_test_results"."end_time",
  "historical_test_results"."score",
  "historical_test_results"."supported",
  "historical_test_results"."failed_rule_count",
  "historical_test_results"."created_at",
  "historical_test_results"."updated_at"
FROM "historical_test_results"
INNER JOIN (
  SELECT "historical_test_results"."tailoring_id", "historical_test_results"."system_id", MAX("historical_test_results"."end_time") AS "end_time"
  FROM "historical_test_results" GROUP BY "historical_test_results"."tailoring_id", "historical_test_results"."system_id"
) AS "tr" ON "historical_test_results"."tailoring_id" = "tr"."tailoring_id" AND
             "historical_test_results"."system_id" = "tr"."system_id" AND
             "historical_test_results"."end_time" = "tr"."end_time";
