CREATE TRIGGER "test_results_delete" INSTEAD OF DELETE ON "test_results"
FOR EACH ROW EXECUTE FUNCTION test_results_delete();
