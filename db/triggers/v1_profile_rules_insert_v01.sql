CREATE TRIGGER "v1_profile_rules_insert" INSTEAD OF INSERT ON "v1_profile_rules"
FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_insert();
