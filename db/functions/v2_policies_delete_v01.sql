CREATE OR REPLACE FUNCTION v2_policies_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE bo_id uuid;
BEGIN
  DELETE FROM "policies" WHERE "id" = OLD."id" RETURNING "business_objective_id" INTO "bo_id";
  -- Delete any remaining business objectives associated with the policy of no other policies use it
  DELETE FROM "business_objectives" WHERE "id" = "bo_id" AND (SELECT COUNT("id") FROM "policies" WHERE "business_objectives"."id" = "bo_id") = 0;
RETURN OLD;
END
$func$;
