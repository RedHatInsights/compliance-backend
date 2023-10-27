CREATE TRIGGER "v2_policies_update" INSTEAD OF UPDATE ON "v2_policies"
FOR EACH ROW EXECUTE FUNCTION v2_policies_update();
