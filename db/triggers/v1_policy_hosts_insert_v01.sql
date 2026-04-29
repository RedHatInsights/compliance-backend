CREATE TRIGGER "v1_policy_hosts_insert" INSTEAD OF INSERT ON "v1_policy_hosts"
FOR EACH ROW EXECUTE FUNCTION v1_policy_hosts_insert();
