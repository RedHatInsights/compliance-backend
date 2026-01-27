CREATE TRIGGER "v1_profiles_delete" INSTEAD OF DELETE ON "v1_profiles"
FOR EACH ROW EXECUTE FUNCTION v1_profiles_delete();
