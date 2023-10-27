CREATE TRIGGER "v2_policies_delete" INSTEAD OF DELETE ON "v2_policies"
FOR EACH ROW EXECUTE FUNCTION v2_policies_delete();
