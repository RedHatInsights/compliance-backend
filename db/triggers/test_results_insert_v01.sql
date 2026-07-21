CREATE TRIGGER "test_results_insert" INSTEAD OF INSERT ON "test_results"
FOR EACH ROW EXECUTE FUNCTION test_results_insert();
