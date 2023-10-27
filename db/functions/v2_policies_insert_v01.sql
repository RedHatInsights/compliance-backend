CREATE OR REPLACE FUNCTION v2_policies_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE bo_id uuid;
DECLARE result_id uuid;
BEGIN
    -- Insert a new business objective record if the business_objective field is
    -- set to a value and return with its ID.
    INSERT INTO "business_objectives" ("title", "created_at", "updated_at")
    SELECT NEW."business_objective", NOW(), NOW()
    WHERE NEW."business_objective" IS NOT NULL RETURNING "id" INTO "bo_id";

    INSERT INTO "policies" (
      "name",
      "description",
      "compliance_threshold",
      "business_objective_id",
      "profile_id",
      "account_id"
    ) VALUES (
      NEW."title",
      NEW."description",
      NEW."compliance_threshold",
      "bo_id",
      NEW."profile_id",
      NEW."account_id"
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
