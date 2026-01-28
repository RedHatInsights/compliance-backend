CREATE OR REPLACE FUNCTION v1_rule_group_relationships_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    UPDATE "rule_group_relationships_v2" SET
      "left_type" = NEW."left_type",
      "left_id" = NEW."left_id",
      "right_type" = NEW."right_type",
      "right_id" = NEW."right_id",
      "relationship" = NEW."relationship",
      "updated_at" = COALESCE(NEW."updated_at", NOW())
    WHERE "id" = OLD."id";

    RETURN NEW;
END
$func$;
