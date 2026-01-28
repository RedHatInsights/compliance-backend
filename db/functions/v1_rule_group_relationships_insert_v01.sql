CREATE OR REPLACE FUNCTION v1_rule_group_relationships_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "rule_group_relationships_v2" (
      "left_type",
      "left_id",
      "right_type",
      "right_id",
      "relationship",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."left_type",
      NEW."left_id",
      NEW."right_type",
      NEW."right_id",
      NEW."relationship",
      COALESCE(NEW."created_at", NOW()),
      COALESCE(NEW."updated_at", NOW())
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
