CREATE OR REPLACE FUNCTION v1_benchmarks_update() RETURNS trigger LANGUAGE plpgsql AS
$func$
BEGIN
    UPDATE "security_guides_v2" SET
      "ref_id" = NEW."ref_id",
      "title" = NEW."title",
      "description" = NEW."description",
      "version" = NEW."version",
      "package_name" = NEW."package_name",
      "updated_at" = COALESCE(NEW."updated_at", NOW())
    WHERE "id" = OLD."id";

    RETURN NEW;
END
$func$;
