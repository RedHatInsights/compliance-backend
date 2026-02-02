CREATE TRIGGER "v1_profile_rules_update" INSTEAD OF UPDATE ON "v1_profile_rules"
FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_update();
