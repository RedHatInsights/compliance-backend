CREATE TRIGGER "v1_rule_group_relationships_update" INSTEAD OF UPDATE ON "v1_rule_group_relationships"
FOR EACH ROW EXECUTE FUNCTION v1_rule_group_relationships_update();
