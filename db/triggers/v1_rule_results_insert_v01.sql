CREATE TRIGGER "v1_rule_results_insert" INSTEAD OF INSERT ON "v1_rule_results"
FOR EACH ROW EXECUTE FUNCTION v1_rule_results_insert();
