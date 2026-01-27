CREATE TRIGGER "v1_profiles_insert" INSTEAD OF INSERT ON "v1_profiles"
FOR EACH ROW EXECUTE FUNCTION v1_profiles_insert();
