CREATE OR REPLACE FUNCTION v1_rule_results_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    DELETE FROM "rule_results_v2" WHERE "id" = OLD."id";
    RETURN OLD;
END
$func$;
