CREATE OR REPLACE FUNCTION rules_v2_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
  -- Delete the rule reference record separately
  DELETE FROM "rule_references_containers" WHERE "rule_id" = OLD."id";
RETURN OLD;
END
$func$;
