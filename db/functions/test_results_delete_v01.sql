CREATE OR REPLACE FUNCTION test_results_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    DELETE FROM "historical_test_results" WHERE "id" = OLD."id";
    RETURN OLD;
END
$func$;
