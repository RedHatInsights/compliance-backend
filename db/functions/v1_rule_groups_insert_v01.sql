CREATE OR REPLACE FUNCTION v1_rule_groups_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "rule_groups_v2" (
      "ref_id",
      "title",
      "description",
      "rationale",
      "ancestry",
      "security_guide_id",
      "rule_id",
      "precedence",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."ref_id",
      NEW."title",
      NEW."description",
      NEW."rationale",
      NEW."ancestry",
      NEW."benchmark_id",
      NEW."rule_id",
      NEW."precedence",
      COALESCE(NEW."created_at", NOW()),
      COALESCE(NEW."updated_at", NOW())
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
