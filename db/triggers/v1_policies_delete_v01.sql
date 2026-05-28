CREATE TRIGGER "v1_policies_delete" INSTEAD OF DELETE ON "v1_policies"
FOR EACH ROW EXECUTE FUNCTION v1_policies_delete();
