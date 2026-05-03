CREATE TRIGGER "v1_policies_insert" INSTEAD OF INSERT ON "v1_policies"
FOR EACH ROW EXECUTE FUNCTION v1_policies_insert();
