CREATE TRIGGER "v2_policies_insert" INSTEAD OF INSERT ON "v2_policies"
FOR EACH ROW EXECUTE FUNCTION v2_policies_insert();
