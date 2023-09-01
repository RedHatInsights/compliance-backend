SELECT
  "value_definitions"."id",
  "value_definitions"."ref_id",
  "value_definitions"."title",
  "value_definitions"."description",
  "value_definitions"."value_type",
  "value_definitions"."default_value",
  "value_definitions"."lower_bound",
  "value_definitions"."upper_bound",
  "value_definitions"."benchmark_id" AS "security_guide_id"
FROM "value_definitions";
