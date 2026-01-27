CREATE OR REPLACE FUNCTION v1_rules_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "rules_v2" (
      "ref_id",
      "title",
      "severity",
      "description",
      "rationale",
      "remediation_available",
      "security_guide_id",
      "upstream",
      "precedence",
      "rule_group_id",
      "value_checks",
      "identifier",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."ref_id",
      NEW."title",
      NEW."severity",
      NEW."description",
      NEW."rationale",
      COALESCE(NEW."remediation_available", FALSE),
      NEW."benchmark_id",
      COALESCE(NEW."upstream", FALSE),
      NEW."precedence",
      NEW."rule_group_id",
      COALESCE(NEW."value_checks", '{}'),
      NEW."identifier",
      COALESCE(NEW."created_at", NOW()),
      COALESCE(NEW."updated_at", NOW())
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
