CREATE OR REPLACE FUNCTION v2_test_results_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "test_results" (
      "profile_id",
      "host_id",
      "start_time",
      "end_time",
      "score",
      "supported",
      "failed_rule_count",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."tailoring_id",
      NEW."system_id",
      NEW."start_time",
      NEW."end_time",
      NEW."score",
      NEW."supported",
      COALESCE(NEW."failed_rule_count", 0),
      NEW."created_at",
      NEW."updated_at"
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
