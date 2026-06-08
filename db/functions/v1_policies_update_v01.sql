CREATE OR REPLACE FUNCTION v1_policies_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE bo_title varchar;
BEGIN
    SELECT "business_objectives"."title" INTO bo_title
    FROM "business_objectives"
    WHERE "business_objectives"."id" = NEW."business_objective_id";

    UPDATE "policies_v2" SET
      "title" = NEW."name",
      "description" = NEW."description",
      "compliance_threshold" = COALESCE(NEW."compliance_threshold", 100.0),
      "business_objective" = bo_title,
      "profile_id" = NEW."profile_id",
      "account_id" = NEW."account_id",
      "updated_at" = NOW()
    WHERE "id" = OLD."id";

    RETURN NEW;
END
$func$;
