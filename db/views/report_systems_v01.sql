SELECT
  "policy_hosts"."id",
  "policy_hosts"."policy_id" AS "report_id",
  "policy_hosts"."host_id" AS "system_id"
FROM "policy_hosts";
