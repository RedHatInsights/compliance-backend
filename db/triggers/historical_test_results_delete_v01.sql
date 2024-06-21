CREATE TRIGGER "historical_test_results_delete" INSTEAD OF DELETE ON "historical_test_results"
FOR EACH ROW EXECUTE FUNCTION v2_test_results_delete();
