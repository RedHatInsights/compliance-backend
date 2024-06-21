SELECT
  "test_results"."id",
  "test_results"."profile_id" "tailoring_id",
  "profiles"."policy_id" "report_id",
  "test_results"."host_id" "system_id",
  "test_results"."start_time",
  "test_results"."end_time",
  "test_results"."score",
  "test_results"."supported",
  "test_results"."failed_rule_count",
  "test_results"."created_at",
  "test_results"."updated_at"
FROM "test_results"
INNER JOIN "profiles" ON "profiles"."id" = "test_results"."profile_id"
INNER JOIN (
  SELECT "test_results"."profile_id", "test_results"."host_id", MAX("test_results"."end_time") AS "end_time"
  FROM "test_results" GROUP BY "test_results"."profile_id", "test_results"."host_id"
) AS "tr" ON "test_results"."profile_id" = "tr"."profile_id" AND
             "test_results"."host_id" = "tr"."host_id" AND
             "test_results"."end_time" = "tr"."end_time";
