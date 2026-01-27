CREATE OR REPLACE FUNCTION v1_rules_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    UPDATE "rules_v2" SET
      "ref_id" = NEW."ref_id",
      "title" = NEW."title",
      "severity" = NEW."severity",
      "description" = NEW."description",
      "rationale" = NEW."rationale",
      "remediation_available" = COALESCE(NEW."remediation_available", FALSE),
      "security_guide_id" = NEW."benchmark_id",
      "upstream" = COALESCE(NEW."upstream", FALSE),
      "precedence" = NEW."precedence",
      "rule_group_id" = NEW."rule_group_id",
      "value_checks" = COALESCE(NEW."value_checks", '{}'),
      "identifier" = NEW."identifier",
      "updated_at" = COALESCE(NEW."updated_at", NOW())
    WHERE "id" = OLD."id";

    RETURN NEW;
END
$func$;
