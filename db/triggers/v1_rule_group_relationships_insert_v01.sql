CREATE TRIGGER "v1_rule_group_relationships_insert" INSTEAD OF INSERT ON "v1_rule_group_relationships"
FOR EACH ROW EXECUTE FUNCTION v1_rule_group_relationships_insert();
