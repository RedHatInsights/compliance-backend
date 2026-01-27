CREATE OR REPLACE FUNCTION v1_value_definitions_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "value_definitions_v2" (
      "ref_id",
      "title",
      "description",
      "value_type",
      "default_value",
      "lower_bound",
      "upper_bound",
      "security_guide_id",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."ref_id",
      NEW."title",
      NEW."description",
      NEW."value_type",
      NEW."default_value",
      NEW."lower_bound",
      NEW."upper_bound",
      NEW."benchmark_id",
      COALESCE(NEW."created_at", NOW()),
      COALESCE(NEW."updated_at", NOW())
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
