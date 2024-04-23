CREATE OR REPLACE FUNCTION v2_rules_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    -- Update the rule reference record separately
    UPDATE "rule_references_container" SET "rule_references" = NEW."references" WHERE "rule_id" = OLD."id";

    UPDATE "rules" SET
      "ref_id" = NEW."ref_id",
      "title" = NEW."title",
      "severity" = NEW."severity",
      "description" = NEW."description",
      "rationale" = NEW."rationale",
      "created_at" = NEW."created_at",
      "updated_at" = NEW."updated_at",
      "remediation_available" = NEW."remediation_available",
      "benchmark_id" = NEW."security_guide_id",
      "upstream" = NEW."upstream",
      "precedence" = NEW."precedence",
      "rule_group_id" = NEW."rule_group_id",
      "value_checks" = NEW."value_checks",
      "identifier" = NEW."identifier"
    WHERE "id" = OLD."id";

    RETURN NEW;
END
$func$;
