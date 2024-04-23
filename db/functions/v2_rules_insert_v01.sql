CREATE OR REPLACE FUNCTION v2_rules_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "rules" (
      "ref_id",
      "title",
      "severity",
      "description",
      "rationale",
      "created_at",
      "updated_at",
      "remediation_available",
      "benchmark_id",
      "upstream",
      "precedence",
      "rule_group_id",
      "value_checks",
      "identifier"
    ) VALUES (
      NEW."ref_id",
      NEW."title",
      NEW."severity",
      NEW."description",
      NEW."rationale",
      NEW."created_at",
      NEW."updated_at",
      NEW."remediation_available",
      NEW."security_guide_id",
      NEW."upstream",
      NEW."precedence",
      NEW."rule_group_id",
      NEW."value_checks",
      NEW."identifier"
    ) RETURNING "id" INTO "result_id";

    -- Insert a new rule reference record separately
    INSERT INTO "rule_references_containers" ("rule_references", "rule_id", "created_at", "updated_at")
    SELECT NEW."references", "result_id", NOW(), NOW();

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
