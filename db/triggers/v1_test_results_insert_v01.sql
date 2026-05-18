CREATE TRIGGER "v1_test_results_insert" INSTEAD OF INSERT ON "v1_test_results"
FOR EACH ROW EXECUTE FUNCTION v1_test_results_insert();
