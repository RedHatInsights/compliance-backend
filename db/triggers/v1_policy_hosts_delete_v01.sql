CREATE TRIGGER "v1_policy_hosts_delete" INSTEAD OF DELETE ON "v1_policy_hosts"
FOR EACH ROW EXECUTE FUNCTION v1_policy_hosts_delete();
