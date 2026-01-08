CREATE OR REPLACE FUNCTION rules_v2_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    -- Update the rule reference record separately
    UPDATE "rule_references_containers" SET "rule_references" = NEW."references" WHERE "rule_id" = OLD."id";

    RETURN NEW;
END
$func$;
