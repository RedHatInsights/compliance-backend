CREATE OR REPLACE FUNCTION rules_v2_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    -- Insert a new rule reference record separately
    INSERT INTO "rule_references_containers" ("rule_references", "rule_id", "created_at", "updated_at")
    SELECT NEW."references", NEW."id", NOW(), NOW();

RETURN NEW;
END
$func$;
