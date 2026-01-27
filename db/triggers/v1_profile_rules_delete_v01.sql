CREATE TRIGGER "v1_profile_rules_delete" INSTEAD OF DELETE ON "v1_profile_rules"
FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_delete();
