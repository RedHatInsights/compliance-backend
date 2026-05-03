CREATE TRIGGER "v1_rule_results_delete" INSTEAD OF DELETE ON "v1_rule_results"
FOR EACH ROW EXECUTE FUNCTION v1_rule_results_delete();
