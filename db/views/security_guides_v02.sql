SELECT
  "benchmarks"."id",
  "benchmarks"."ref_id",
  REGEXP_REPLACE("benchmarks"."ref_id", '.+RHEL-(\d+)$', '\1')::int AS "os_major_version",
  "benchmarks"."title",
  "benchmarks"."description",
  "benchmarks"."version",
  "benchmarks"."created_at",
  "benchmarks"."updated_at",
  "benchmarks"."package_name"
FROM "benchmarks";
