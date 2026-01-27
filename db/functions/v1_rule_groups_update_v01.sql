CREATE OR REPLACE FUNCTION v1_rule_groups_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    UPDATE "rule_groups_v2" SET
      "ref_id" = NEW."ref_id",
      "title" = NEW."title",
      "description" = NEW."description",
      "rationale" = NEW."rationale",
      "ancestry" = NEW."ancestry",
      "security_guide_id" = NEW."benchmark_id",
      "rule_id" = NEW."rule_id",
      "precedence" = NEW."precedence",
      "updated_at" = COALESCE(NEW."updated_at", NOW())
    WHERE "id" = OLD."id";

    RETURN NEW;
END
$func$;
