SELECT
  "test_results"."id",
  "test_results"."profile_id" "tailoring_id",
  "test_results"."host_id" "system_id",
  "test_results"."start_time",
  "test_results"."end_time",
  "test_results"."score",
  "test_results"."supported",
  "test_results"."created_at",
  "test_results"."updated_at"
from "test_results";
