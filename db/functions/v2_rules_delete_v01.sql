CREATE OR REPLACE FUNCTION v2_rules_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
  -- Delete the rule reference record separately
  DELETE FROM "rule_references_containers" WHERE "rule_id" = OLD."id";
  DELETE FROM "rules" WHERE "id" = OLD."id";
RETURN OLD;
END
$func$;
