CREATE OR REPLACE FUNCTION v1_policy_hosts_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "policy_systems_v2" (
      "policy_id",
      "system_id",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."policy_id",
      NEW."host_id",
      COALESCE(NEW."created_at", NOW()),
      COALESCE(NEW."updated_at", NOW())
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
