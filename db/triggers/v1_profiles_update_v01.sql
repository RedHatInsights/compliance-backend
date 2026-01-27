CREATE TRIGGER "v1_profiles_update" INSTEAD OF UPDATE ON "v1_profiles"
FOR EACH ROW EXECUTE FUNCTION v1_profiles_update();
