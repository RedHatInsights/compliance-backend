CREATE OR REPLACE FUNCTION v2_policies_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE "bo_id" uuid;
BEGIN
    -- Create a new business objective record if the apropriate field is set and there is no
    -- existing business objective already assigned to the policy and return with its ID.
    INSERT INTO "business_objectives" ("title", "created_at", "updated_at")
    SELECT NEW."business_objective", NOW(), NOW() FROM "policies" WHERE
      NEW."business_objective" IS NOT NULL AND
      "policies"."business_objective_id" IS NULL AND
      "policies"."id" = OLD."id"
    RETURNING "id" INTO "bo_id";

    -- If the previous insertion was successful, there is nothing to update, otherwise try to
    -- update any existing business objective assigned to the policy and return with its ID.
    IF "bo_id" IS NULL THEN
      UPDATE "business_objectives" SET "title" = NEW."business_objective", "updated_at" = NOW()
      FROM "policies" WHERE
        "policies"."business_objective_id" = "business_objectives"."id" AND
        "policies"."id" = OLD."id"
      RETURNING "business_objectives"."id" INTO "bo_id";
    END IF;

    -- Update the policy itself, use the ID of the business objective from the previous two queries,
    -- if the business_objective field is set to NULL, remove the link between the two tables.
    UPDATE "policies" SET
      "name" = NEW."title",
      "description" = NEW."description",
      "compliance_threshold" = NEW."compliance_threshold",
      "business_objective_id" = CASE WHEN NEW."business_objective" IS NULL THEN NULL ELSE "bo_id" END
    WHERE "id" = OLD."id";

    -- If the business_objective field is set to NULL, delete its record in the business objectives
    -- table using the ID retrieved during the second query.
    DELETE FROM "business_objectives" USING "policies"
    WHERE NEW."business_objective" IS NULL AND "business_objectives"."id" = "bo_id";

    RETURN NEW;
END
$func$;
