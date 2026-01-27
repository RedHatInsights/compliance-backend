CREATE OR REPLACE FUNCTION v1_profiles_delete() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    IF OLD."parent_profile_id" IS NOT NULL THEN
        DELETE FROM "profiles" WHERE "id" = OLD."id";
    END IF;

    RETURN OLD;
END
$func$;
