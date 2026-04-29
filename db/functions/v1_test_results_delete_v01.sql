CREATE OR REPLACE FUNCTION v1_test_results_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    DELETE FROM "historical_test_results_v2" WHERE "id" = OLD."id";
    RETURN OLD;
END
$func$;
