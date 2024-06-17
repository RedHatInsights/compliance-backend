CREATE OR REPLACE FUNCTION v2_test_results_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
  -- Delete the test_result records belonging to report
  DELETE FROM "test_results" WHERE "id" = OLD."id";
RETURN OLD;
END
$func$;
