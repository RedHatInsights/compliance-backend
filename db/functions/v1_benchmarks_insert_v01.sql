CREATE OR REPLACE FUNCTION v1_benchmarks_insert() RETURNS trigger LANGUAGE plpgsql AS
$func$
DECLARE result_id uuid;
BEGIN
    INSERT INTO "security_guides_v2" (
      "ref_id",
      "title",
      "description",
      "version",
      "os_major_version",
      "package_name",
      "created_at",
      "updated_at"
    ) VALUES (
      NEW."ref_id",
      NEW."title",
      NEW."description",
      NEW."version",
      CAST(REGEXP_REPLACE(NEW."ref_id", '.+RHEL-(\d+)$', '\1') AS int),
      NEW."package_name",
      COALESCE(NEW."created_at", NOW()),
      COALESCE(NEW."updated_at", NOW())
    ) RETURNING "id" INTO "result_id";

    NEW."id" := "result_id";
    RETURN NEW;
END
$func$;
