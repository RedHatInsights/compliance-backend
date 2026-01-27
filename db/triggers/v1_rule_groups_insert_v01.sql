CREATE TRIGGER "v1_rule_groups_insert" INSTEAD OF INSERT ON "v1_rule_groups"
FOR EACH ROW EXECUTE FUNCTION v1_rule_groups_insert();
