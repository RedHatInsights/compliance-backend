CREATE TRIGGER "v1_rule_groups_update" INSTEAD OF UPDATE ON "v1_rule_groups"
FOR EACH ROW EXECUTE FUNCTION v1_rule_groups_update();
