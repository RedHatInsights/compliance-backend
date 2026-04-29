CREATE OR REPLACE FUNCTION v1_policies_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
DECLARE bo_title varchar;
BEGIN
    SELECT "business_objectives"."title" INTO bo_title
    FROM "business_objectives"
    WHERE "business_objectives"."id" = NEW."business_objective_id";

    INSERT INTO "policies_v2" (
      "title",
      "description",
      "compliance_threshold",
      "business_objective",
      "profile_id",
      "account_id",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."name",
      NEW."description",
      COALESCE(NEW."compliance_threshold", 100.0),
      bo_title,
      NEW."profile_id",
      NEW."account_id",
      NOW(),
      NOW()
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
