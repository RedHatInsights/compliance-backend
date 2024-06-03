CREATE TRIGGER "v2_test_results_insert" INSTEAD OF INSERT ON "v2_test_results"
FOR EACH ROW EXECUTE FUNCTION v2_test_results_insert();
