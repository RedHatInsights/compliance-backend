CREATE OR REPLACE FUNCTION v1_policies_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    DELETE FROM "policies_v2" WHERE "id" = OLD."id";
    RETURN OLD;
END
$func$;
