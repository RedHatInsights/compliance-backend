CREATE OR REPLACE FUNCTION v1_rule_results_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "rule_results_v2" (
      "result",
      "rule_id",
      "test_result_id",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."result",
      NEW."rule_id",
      NEW."test_result_id",
      COALESCE(NEW."created_at", NOW()),
      COALESCE(NEW."updated_at", NOW())
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
