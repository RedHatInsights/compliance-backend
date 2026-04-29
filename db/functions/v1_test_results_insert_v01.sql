CREATE OR REPLACE FUNCTION v1_test_results_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
DECLARE v_report_id uuid;
BEGIN
    SELECT "tailorings_v2"."policy_id" INTO v_report_id
    FROM "tailorings_v2"
    WHERE "tailorings_v2"."id" = NEW."profile_id";

    INSERT INTO "historical_test_results_v2" (
      "tailoring_id",
      "report_id",
      "system_id",
      "start_time",
      "end_time",
      "score",
      "supported",
      "failed_rule_count",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."profile_id",
      v_report_id,
      NEW."host_id",
      NEW."start_time",
      NEW."end_time",
      NEW."score",
      COALESCE(NEW."supported", TRUE),
      COALESCE(NEW."failed_rule_count", 0),
      COALESCE(NEW."created_at", NOW()),
      COALESCE(NEW."updated_at", NOW())
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
