CREATE TRIGGER "v1_policies_update" INSTEAD OF UPDATE ON "v1_policies"
FOR EACH ROW EXECUTE FUNCTION v1_policies_update();
