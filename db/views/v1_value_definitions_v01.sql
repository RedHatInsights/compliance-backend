SELECT
  "value_definitions_v2"."id",
  "value_definitions_v2"."ref_id",
  "value_definitions_v2"."title",
  "value_definitions_v2"."description",
  "value_definitions_v2"."value_type",
  "value_definitions_v2"."default_value",
  "value_definitions_v2"."lower_bound",
  "value_definitions_v2"."upper_bound",
  "value_definitions_v2"."security_guide_id" AS "benchmark_id",
  "value_definitions_v2"."created_at",
  "value_definitions_v2"."updated_at"
FROM "value_definitions_v2";
