CREATE TRIGGER "v1_test_results_delete" INSTEAD OF DELETE ON "v1_test_results"
FOR EACH ROW EXECUTE FUNCTION v1_test_results_delete();
