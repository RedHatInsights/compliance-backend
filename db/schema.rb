# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_24_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "dblink"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "org_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["org_id"], name: "index_accounts_on_org_id", unique: true
  end

  create_table "canonical_profiles_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.string "ref_id"
    t.uuid "security_guide_id", null: false
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "upstream"
    t.jsonb "value_overrides", default: {}
    t.index ["ref_id", "security_guide_id"], name: "index_canonical_profiles_v2_on_ref_id_and_security_guide_id", unique: true
    t.index ["title"], name: "index_canonical_profiles_v2_on_title"
    t.index ["upstream"], name: "index_canonical_profiles_v2_on_upstream"
  end

  create_table "fixes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "complexity"
    t.datetime "created_at"
    t.string "disruption"
    t.uuid "rule_id", null: false
    t.string "strategy"
    t.string "system"
    t.text "text"
    t.datetime "updated_at"
    t.index ["rule_id", "system"], name: "index_fixes_on_rule_id_and_system", unique: true
    t.index ["rule_id"], name: "index_fixes_on_rule_id"
    t.index ["system"], name: "index_fixes_on_system"
  end

  create_table "historical_test_results_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "end_time", precision: nil
    t.integer "failed_rule_count", default: 0, null: false
    t.uuid "report_id", null: false
    t.decimal "score"
    t.datetime "start_time", precision: nil
    t.boolean "supported", default: true, null: false
    t.uuid "system_id", null: false
    t.uuid "tailoring_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["supported"], name: "index_historical_test_results_v2_on_supported"
    t.index ["system_id", "tailoring_id", "end_time"], name: "index_historical_test_results_v2_on_system_tailoring_end_time", unique: true
    t.index ["system_id"], name: "index_historical_test_results_v2_on_system_id"
    t.index ["tailoring_id", "system_id", "end_time"], name: "index_historical_test_results_v2_for_latest_lookup", order: { end_time: :desc }, include: ["id"]
    t.index ["tailoring_id"], name: "index_historical_test_results_v2_on_tailoring_id"
  end

  create_table "policies_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "business_objective"
    t.float "compliance_threshold", default: 100.0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.uuid "profile_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_policies_v2_on_account_id"
    t.index ["profile_id"], name: "index_policies_v2_on_profile_id"
  end

  create_table "policy_systems_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.uuid "policy_id", null: false
    t.uuid "system_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["policy_id", "system_id"], name: "index_policy_systems_v2_on_policy_id_and_system_id", unique: true
    t.index ["policy_id"], name: "index_policy_systems_v2_on_policy_id"
    t.index ["system_id"], name: "index_policy_systems_v2_on_system_id"
  end

  create_table "profile_os_minor_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "os_minor_version"
    t.uuid "profile_id"
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_profile_os_minor_versions_on_profile_id"
  end

  create_table "profile_rules_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "profile_id", null: false
    t.uuid "rule_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["profile_id", "rule_id"], name: "index_profile_rules_v2_on_profile_id_and_rule_id", unique: true
    t.index ["profile_id"], name: "index_profile_rules_v2_on_profile_id"
    t.index ["rule_id"], name: "index_profile_rules_v2_on_rule_id"
  end

  create_table "revisions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.string "revision", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_revisions_on_name", unique: true
  end

  create_table "rule_group_relationships_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "left_id", null: false
    t.string "left_type"
    t.string "relationship", null: false
    t.uuid "right_id", null: false
    t.string "right_type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["left_id", "right_id", "right_type", "left_type", "relationship"], name: "unique_index_rule_group_relationships_v2", unique: true
    t.index ["left_type", "left_id"], name: "index_rule_group_relationships_v2_on_left"
    t.index ["right_type", "right_id"], name: "index_rule_group_relationships_v2_on_right"
  end

  create_table "rule_groups_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ancestry"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.integer "precedence"
    t.text "rationale"
    t.string "ref_id"
    t.uuid "rule_id"
    t.uuid "security_guide_id", null: false
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ancestry"], name: "index_rule_groups_v2_on_ancestry"
    t.index ["precedence"], name: "index_rule_groups_v2_on_precedence"
    t.index ["ref_id", "security_guide_id"], name: "index_rule_groups_v2_on_ref_id_and_security_guide_id", unique: true
    t.index ["rule_id"], name: "index_rule_groups_v2_on_rule_id", unique: true
    t.index ["security_guide_id"], name: "index_rule_groups_v2_on_security_guide_id"
  end

  create_table "rule_results_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "result"
    t.uuid "rule_id", null: false
    t.uuid "test_result_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["rule_id"], name: "index_rule_results_v2_on_rule_id"
    t.index ["test_result_id", "result"], name: "index_rule_results_v2_on_test_result_id_and_result"
    t.index ["test_result_id", "rule_id"], name: "index_rule_results_v2_on_test_result_id_and_rule_id", unique: true
    t.index ["test_result_id"], name: "index_rule_results_v2_on_test_result_id"
  end

  create_table "rules_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.jsonb "identifier"
    t.integer "precedence"
    t.text "rationale"
    t.string "ref_id"
    t.jsonb "references"
    t.boolean "remediation_available", default: false, null: false
    t.uuid "rule_group_id"
    t.uuid "security_guide_id", null: false
    t.string "severity"
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "upstream", default: false, null: false
    t.uuid "value_checks", default: [], array: true
    t.index "((identifier -> 'label'::text))", name: "index_rules_v2_on_identifier_labels", using: :gin
    t.index ["precedence"], name: "index_rules_v2_on_precedence"
    t.index ["ref_id", "security_guide_id"], name: "index_rules_v2_on_ref_id_and_security_guide_id", unique: true
    t.index ["ref_id"], name: "index_rules_v2_on_ref_id"
    t.index ["references"], name: "index_rules_v2_on_references", opclass: :jsonb_path_ops, using: :gin
    t.index ["severity"], name: "index_rules_v2_on_severity"
    t.index ["upstream"], name: "index_rules_v2_on_upstream"
  end

  create_table "security_guides_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description", null: false
    t.integer "os_major_version", null: false
    t.string "package_name"
    t.string "ref_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "version", null: false
    t.index ["ref_id", "version"], name: "index_security_guides_v2_on_ref_id_and_version", unique: true
  end

  create_table "systems", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "account", limit: 10
    t.datetime "created", null: false
    t.datetime "deleted_at"
    t.string "display_name", limit: 200, null: false
    t.jsonb "groups", default: []
    t.uuid "insights_id"
    t.string "org_id", limit: 10, null: false
    t.datetime "stale_timestamp", null: false
    t.jsonb "system_profile", default: {}, null: false
    t.jsonb "tags", default: {}, null: false
    t.datetime "updated", null: false
    t.index ["insights_id"], name: "index_systems_on_insights_id"
  end

  create_table "tailoring_rules_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.uuid "rule_id", null: false
    t.uuid "tailoring_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["rule_id"], name: "index_tailoring_rules_v2_on_rule_id"
    t.index ["tailoring_id", "rule_id"], name: "index_tailoring_rules_v2_on_tailoring_id_and_rule_id", unique: true
    t.index ["tailoring_id"], name: "index_tailoring_rules_v2_on_tailoring_id"
  end

  create_table "tailorings_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "os_minor_version"
    t.uuid "policy_id", null: false
    t.uuid "profile_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "value_overrides", default: {}
    t.index ["policy_id"], name: "index_tailorings_v2_on_policy_id"
    t.index ["profile_id"], name: "index_tailorings_v2_on_profile_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.boolean "active"
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.string "first_name"
    t.boolean "internal"
    t.string "lang"
    t.string "last_name"
    t.string "locale"
    t.boolean "org_admin"
    t.string "redhat_id"
    t.string "redhat_org_id"
    t.datetime "updated_at", precision: nil, null: false
    t.string "username"
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  create_table "value_definitions_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "default_value"
    t.text "description"
    t.decimal "lower_bound"
    t.string "ref_id"
    t.uuid "security_guide_id", null: false
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "upper_bound"
    t.string "value_type"
    t.index ["ref_id", "security_guide_id"], name: "index_value_definitions_v2_on_ref_id_and_security_guide_id", unique: true
    t.index ["security_guide_id"], name: "index_value_definitions_v2_on_security_guide_id"
  end

  add_foreign_key "policies_v2", "accounts"
  add_foreign_key "policies_v2", "canonical_profiles_v2", column: "profile_id"
  add_foreign_key "policy_systems_v2", "policies_v2", column: "policy_id"
  add_foreign_key "rule_groups_v2", "rules_v2", column: "rule_id"
  add_foreign_key "rule_groups_v2", "security_guides_v2", column: "security_guide_id"
  add_foreign_key "rules_v2", "rule_groups_v2", column: "rule_group_id"
  add_foreign_key "tailorings_v2", "canonical_profiles_v2", column: "profile_id"
  add_foreign_key "tailorings_v2", "policies_v2", column: "policy_id"
  add_foreign_key "value_definitions_v2", "security_guides_v2", column: "security_guide_id"


  create_view "report_systems", sql_definition: <<-SQL
      SELECT id,
      policy_id AS report_id,
      system_id
     FROM policy_systems_v2;
  SQL
  create_view "supported_profiles", sql_definition: <<-SQL
      SELECT (array_agg(canonical_profiles_v2.id ORDER BY (string_to_array((security_guides_v2.version)::text, '.'::text))::integer[] DESC))[1] AS id,
      (array_agg(canonical_profiles_v2.title ORDER BY (string_to_array((security_guides_v2.version)::text, '.'::text))::integer[] DESC))[1] AS title,
      (array_agg(canonical_profiles_v2.description ORDER BY (string_to_array((security_guides_v2.version)::text, '.'::text))::integer[] DESC))[1] AS description,
      canonical_profiles_v2.ref_id,
      (array_agg(security_guides_v2.id ORDER BY (string_to_array((security_guides_v2.version)::text, '.'::text))::integer[] DESC))[1] AS security_guide_id,
      (array_agg(security_guides_v2.version ORDER BY (string_to_array((security_guides_v2.version)::text, '.'::text))::integer[] DESC))[1] AS security_guide_version,
      security_guides_v2.os_major_version,
      array_agg(DISTINCT profile_os_minor_versions.os_minor_version ORDER BY profile_os_minor_versions.os_minor_version DESC) AS os_minor_versions
     FROM ((canonical_profiles_v2
       JOIN security_guides_v2 ON ((security_guides_v2.id = canonical_profiles_v2.security_guide_id)))
       JOIN profile_os_minor_versions ON ((profile_os_minor_versions.profile_id = canonical_profiles_v2.id)))
    GROUP BY canonical_profiles_v2.ref_id, security_guides_v2.os_major_version;
  SQL
  create_view "v1_benchmarks", sql_definition: <<-SQL
      SELECT id,
      ref_id,
      title,
      description,
      version,
      created_at,
      updated_at,
      package_name
     FROM security_guides_v2;
  SQL
  create_view "v1_policy_hosts", sql_definition: <<-SQL
      SELECT id,
      policy_id,
      system_id AS host_id,
      created_at,
      updated_at
     FROM policy_systems_v2;
  SQL
  create_view "v1_profile_rules", sql_definition: <<-SQL
      SELECT profile_rules_v2.id,
      profile_rules_v2.profile_id,
      profile_rules_v2.rule_id,
      profile_rules_v2.created_at,
      profile_rules_v2.updated_at
     FROM profile_rules_v2
  UNION ALL
   SELECT tailoring_rules_v2.id,
      tailoring_rules_v2.tailoring_id AS profile_id,
      tailoring_rules_v2.rule_id,
      tailoring_rules_v2.created_at,
      tailoring_rules_v2.updated_at
     FROM tailoring_rules_v2;
  SQL
  create_view "v1_profiles", sql_definition: <<-SQL
      SELECT canonical_profiles_v2.id,
      canonical_profiles_v2.title AS name,
      canonical_profiles_v2.ref_id,
      canonical_profiles_v2.created_at,
      canonical_profiles_v2.updated_at,
      canonical_profiles_v2.description,
      NULL::uuid AS account_id,
      canonical_profiles_v2.security_guide_id AS benchmark_id,
      NULL::uuid AS parent_profile_id,
      false AS external,
      NULL::uuid AS policy_id,
      NULL::character varying AS os_minor_version,
      NULL::numeric AS score,
      canonical_profiles_v2.upstream,
      canonical_profiles_v2.value_overrides
     FROM canonical_profiles_v2
  UNION ALL
   SELECT tailorings_v2.id,
      cp.title AS name,
      cp.ref_id,
      tailorings_v2.created_at,
      tailorings_v2.updated_at,
      cp.description,
      p.account_id,
      cp.security_guide_id AS benchmark_id,
      tailorings_v2.profile_id AS parent_profile_id,
      false AS external,
      tailorings_v2.policy_id,
      COALESCE((tailorings_v2.os_minor_version)::character varying, ''::character varying) AS os_minor_version,
      NULL::numeric AS score,
      false AS upstream,
      tailorings_v2.value_overrides
     FROM ((tailorings_v2
       JOIN canonical_profiles_v2 cp ON ((cp.id = tailorings_v2.profile_id)))
       JOIN policies_v2 p ON ((p.id = tailorings_v2.policy_id)));
  SQL
  create_view "v1_rule_group_relationships", sql_definition: <<-SQL
      SELECT id,
      left_type,
      left_id,
      right_type,
      right_id,
      relationship,
      created_at,
      updated_at
     FROM rule_group_relationships_v2;
  SQL
  create_view "v1_rule_groups", sql_definition: <<-SQL
      SELECT id,
      ref_id,
      title,
      description,
      rationale,
      ancestry,
      security_guide_id AS benchmark_id,
      rule_id,
      precedence,
      created_at,
      updated_at
     FROM rule_groups_v2;
  SQL
  create_view "v1_rule_references_containers", sql_definition: <<-SQL
      SELECT id,
      id AS rule_id,
      "references" AS rule_references,
      created_at,
      updated_at
     FROM rules_v2;
  SQL
  create_view "v1_rule_results", sql_definition: <<-SQL
      SELECT rule_results_v2.id,
      historical_test_results_v2.system_id AS host_id,
      rule_results_v2.result,
      rule_results_v2.rule_id,
      rule_results_v2.test_result_id,
      rule_results_v2.created_at,
      rule_results_v2.updated_at
     FROM (rule_results_v2
       JOIN historical_test_results_v2 ON ((historical_test_results_v2.id = rule_results_v2.test_result_id)));
  SQL
  create_view "v1_rules", sql_definition: <<-SQL
      SELECT id,
      ref_id,
      NULL::boolean AS supported,
      title,
      severity,
      description,
      rationale,
      created_at,
      updated_at,
      lower(replace((ref_id)::text, '.'::text, '-'::text)) AS slug,
      remediation_available,
      security_guide_id AS benchmark_id,
      upstream,
      precedence,
      rule_group_id,
      value_checks,
      identifier
     FROM rules_v2;
  SQL
  create_view "v1_test_results", sql_definition: <<-SQL
      SELECT id,
      tailoring_id AS profile_id,
      system_id AS host_id,
      start_time,
      end_time,
      score,
      supported,
      failed_rule_count,
      created_at,
      updated_at
     FROM historical_test_results_v2;
  SQL
  create_view "v1_value_definitions", sql_definition: <<-SQL
      SELECT id,
      ref_id,
      title,
      description,
      value_type,
      default_value,
      lower_bound,
      upper_bound,
      security_guide_id AS benchmark_id,
      created_at,
      updated_at
     FROM value_definitions_v2;
  SQL
  create_view "v2_test_results", sql_definition: <<-SQL
      SELECT historical_test_results_v2.id,
      historical_test_results_v2.tailoring_id,
      historical_test_results_v2.report_id,
      historical_test_results_v2.system_id,
      historical_test_results_v2.start_time,
      historical_test_results_v2.end_time,
      historical_test_results_v2.score,
      historical_test_results_v2.supported,
      historical_test_results_v2.failed_rule_count,
      historical_test_results_v2.created_at,
      historical_test_results_v2.updated_at
     FROM (historical_test_results_v2
       JOIN ( SELECT historical_test_results_v2_1.tailoring_id,
              historical_test_results_v2_1.system_id,
              max(historical_test_results_v2_1.end_time) AS end_time
             FROM historical_test_results_v2 historical_test_results_v2_1
            GROUP BY historical_test_results_v2_1.tailoring_id, historical_test_results_v2_1.system_id) tr ON (((historical_test_results_v2.tailoring_id = tr.tailoring_id) AND (historical_test_results_v2.system_id = tr.system_id) AND (historical_test_results_v2.end_time = tr.end_time))));
  SQL

  create_function :v2_test_results_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_test_results_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "historical_test_results_v2" (
            "tailoring_id",
            "report_id",
            "system_id",
            "start_time",
            "end_time",
            "score",
            "supported",
            "failed_rule_count",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."tailoring_id",
            NEW."report_id",
            NEW."system_id",
            NEW."start_time",
            NEW."end_time",
            NEW."score",
            NEW."supported",
            COALESCE(NEW."failed_rule_count", 0),
            COALESCE(NEW."created_at", NOW()),
            COALESCE(NEW."updated_at", NOW())
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v2_test_results_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_test_results_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          DELETE FROM "historical_test_results_v2" WHERE "id" = OLD."id";
          RETURN OLD;
      END
      $function$
  SQL

  create_function :v1_benchmarks_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_benchmarks_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
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
      $function$
  SQL

  create_function :v1_benchmarks_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_benchmarks_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          UPDATE "security_guides_v2" SET
            "ref_id" = NEW."ref_id",
            "os_major_version" = CAST(REGEXP_REPLACE(NEW."ref_id", '.+RHEL-(\d+)$', '\1') AS int),
            "title" = NEW."title",
            "description" = NEW."description",
            "version" = NEW."version",
            "package_name" = NEW."package_name",
            "updated_at" = COALESCE(NEW."updated_at", NOW())
          WHERE "id" = OLD."id";

          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_rules_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_rules_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "rules_v2" (
            "ref_id",
            "title",
            "severity",
            "description",
            "rationale",
            "remediation_available",
            "security_guide_id",
            "upstream",
            "precedence",
            "rule_group_id",
            "value_checks",
            "identifier",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."ref_id",
            NEW."title",
            NEW."severity",
            NEW."description",
            NEW."rationale",
            COALESCE(NEW."remediation_available", FALSE),
            NEW."benchmark_id",
            COALESCE(NEW."upstream", FALSE),
            NEW."precedence",
            NEW."rule_group_id",
            COALESCE(NEW."value_checks", '{}'),
            NEW."identifier",
            COALESCE(NEW."created_at", NOW()),
            COALESCE(NEW."updated_at", NOW())
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_rules_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_rules_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          UPDATE "rules_v2" SET
            "ref_id" = NEW."ref_id",
            "title" = NEW."title",
            "severity" = NEW."severity",
            "description" = NEW."description",
            "rationale" = NEW."rationale",
            "remediation_available" = COALESCE(NEW."remediation_available", FALSE),
            "security_guide_id" = NEW."benchmark_id",
            "upstream" = COALESCE(NEW."upstream", FALSE),
            "precedence" = NEW."precedence",
            "rule_group_id" = NEW."rule_group_id",
            "value_checks" = COALESCE(NEW."value_checks", '{}'),
            "identifier" = NEW."identifier",
            "updated_at" = COALESCE(NEW."updated_at", NOW())
          WHERE "id" = OLD."id";

          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_value_definitions_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_value_definitions_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "value_definitions_v2" (
            "ref_id",
            "title",
            "description",
            "value_type",
            "default_value",
            "lower_bound",
            "upper_bound",
            "security_guide_id",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."ref_id",
            NEW."title",
            NEW."description",
            NEW."value_type",
            NEW."default_value",
            NEW."lower_bound",
            NEW."upper_bound",
            NEW."benchmark_id",
            COALESCE(NEW."created_at", NOW()),
            COALESCE(NEW."updated_at", NOW())
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_rule_groups_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_rule_groups_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "rule_groups_v2" (
            "ref_id",
            "title",
            "description",
            "rationale",
            "ancestry",
            "security_guide_id",
            "rule_id",
            "precedence",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."ref_id",
            NEW."title",
            NEW."description",
            NEW."rationale",
            NEW."ancestry",
            NEW."benchmark_id",
            NEW."rule_id",
            NEW."precedence",
            COALESCE(NEW."created_at", NOW()),
            COALESCE(NEW."updated_at", NOW())
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_rule_groups_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_rule_groups_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          UPDATE "rule_groups_v2" SET
            "ref_id" = NEW."ref_id",
            "title" = NEW."title",
            "description" = NEW."description",
            "rationale" = NEW."rationale",
            "ancestry" = NEW."ancestry",
            "security_guide_id" = NEW."benchmark_id",
            "rule_id" = NEW."rule_id",
            "precedence" = NEW."precedence",
            "updated_at" = COALESCE(NEW."updated_at", NOW())
          WHERE "id" = OLD."id";

          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_rule_group_relationships_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_rule_group_relationships_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "rule_group_relationships_v2" (
            "left_type",
            "left_id",
            "right_type",
            "right_id",
            "relationship",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."left_type",
            NEW."left_id",
            NEW."right_type",
            NEW."right_id",
            NEW."relationship",
            COALESCE(NEW."created_at", NOW()),
            COALESCE(NEW."updated_at", NOW())
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_rule_group_relationships_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_rule_group_relationships_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
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
      $function$
  SQL

  create_function :v1_profile_rules_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_profile_rules_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE
          result_id uuid;
          is_tailoring boolean;
      BEGIN
          SELECT EXISTS(
              SELECT 1 FROM "tailorings_v2"
              WHERE "id" = NEW."profile_id"
          ) INTO is_tailoring;

          IF is_tailoring THEN
              INSERT INTO "tailoring_rules_v2" (
                "tailoring_id",
                "rule_id",
                "created_at",
                "updated_at"
              ) VALUES (
                NEW."profile_id",
                NEW."rule_id",
                COALESCE(NEW."created_at", NOW()),
                COALESCE(NEW."updated_at", NOW())
              ) RETURNING "id" INTO "result_id";
          ELSE
              INSERT INTO "profile_rules_v2" (
                "profile_id",
                "rule_id",
                "created_at",
                "updated_at"
              ) VALUES (
                NEW."profile_id",
                NEW."rule_id",
                COALESCE(NEW."created_at", NOW()),
                COALESCE(NEW."updated_at", NOW())
              ) RETURNING "id" INTO "result_id";
          END IF;

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_profile_rules_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_profile_rules_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE
          is_tailoring boolean;
      BEGIN
          SELECT EXISTS(
              SELECT 1 FROM "tailorings_v2"
              WHERE "id" = NEW."profile_id"
          ) INTO is_tailoring;

          IF is_tailoring THEN
              UPDATE "tailoring_rules_v2" SET
                "tailoring_id" = NEW."profile_id",
                "rule_id" = NEW."rule_id",
                "updated_at" = COALESCE(NEW."updated_at", NOW())
              WHERE "id" = OLD."id";
          ELSE
              UPDATE "profile_rules_v2" SET
                "profile_id" = NEW."profile_id",
                "rule_id" = NEW."rule_id",
                "updated_at" = COALESCE(NEW."updated_at", NOW())
              WHERE "id" = OLD."id";
          END IF;

          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_profile_rules_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_profile_rules_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE
          is_tailoring boolean;
      BEGIN
          SELECT EXISTS(
              SELECT 1 FROM "tailorings_v2"
              WHERE "id" = OLD."profile_id"
          ) INTO is_tailoring;

          IF is_tailoring THEN
              DELETE FROM "tailoring_rules_v2" WHERE "id" = OLD."id";
          ELSE
              DELETE FROM "profile_rules_v2" WHERE "id" = OLD."id";
          END IF;

          RETURN OLD;
      END
      $function$
  SQL

  create_function :v1_test_results_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_test_results_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE
          result_id uuid;
          v_report_id uuid;
      BEGIN
          SELECT "tailorings_v2"."policy_id" INTO v_report_id
          FROM "tailorings_v2"
          WHERE "tailorings_v2"."id" = NEW."profile_id";

          INSERT INTO "historical_test_results_v2" (
            "tailoring_id",
            "report_id",
            "system_id",
            "start_time",
            "end_time",
            "score",
            "supported",
            "failed_rule_count",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."profile_id",
            v_report_id,
            NEW."host_id",
            NEW."start_time",
            NEW."end_time",
            NEW."score",
            COALESCE(NEW."supported", TRUE),
            COALESCE(NEW."failed_rule_count", 0),
            COALESCE(NEW."created_at", NOW()),
            COALESCE(NEW."updated_at", NOW())
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_test_results_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_test_results_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          DELETE FROM "historical_test_results_v2" WHERE "id" = OLD."id";
          RETURN OLD;
      END
      $function$
  SQL

  create_function :v1_policy_hosts_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_policy_hosts_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "policy_systems_v2" (
            "policy_id",
            "system_id",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."policy_id",
            NEW."host_id",
            COALESCE(NEW."created_at", NOW()),
            COALESCE(NEW."updated_at", NOW())
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_policy_hosts_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_policy_hosts_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          DELETE FROM "policy_systems_v2" WHERE "id" = OLD."id";
          RETURN OLD;
      END
      $function$
  SQL

  create_function :v1_profiles_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_profiles_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          IF NEW."parent_profile_id" IS NULL THEN
              INSERT INTO "canonical_profiles_v2" (
                "title",
                "ref_id",
                "description",
                "security_guide_id",
                "upstream",
                "value_overrides",
                "created_at",
                "updated_at"
              ) VALUES (
                NEW."name",
                NEW."ref_id",
                NEW."description",
                NEW."benchmark_id",
                COALESCE(NEW."upstream", FALSE),
                COALESCE(NEW."value_overrides", '{}'),
                COALESCE(NEW."created_at", NOW()),
                COALESCE(NEW."updated_at", NOW())
              ) RETURNING "id" INTO "result_id";
          ELSE
              INSERT INTO "tailorings_v2" (
                "policy_id",
                "profile_id",
                "value_overrides",
                "os_minor_version",
                "created_at",
                "updated_at"
              ) VALUES (
                NEW."policy_id",
                NEW."parent_profile_id",
                COALESCE(NEW."value_overrides", '{}'),
                CAST(NULLIF(NEW."os_minor_version", '') AS int),
                COALESCE(NEW."created_at", NOW()),
                COALESCE(NEW."updated_at", NOW())
              ) RETURNING "id" INTO "result_id";
          END IF;

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_profiles_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_profiles_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          IF OLD."parent_profile_id" IS NULL THEN
              UPDATE "canonical_profiles_v2" SET
                "title" = NEW."name",
                "ref_id" = NEW."ref_id",
                "description" = NEW."description",
                "security_guide_id" = NEW."benchmark_id",
                "upstream" = COALESCE(NEW."upstream", FALSE),
                "value_overrides" = COALESCE(NEW."value_overrides", '{}'),
                "updated_at" = COALESCE(NEW."updated_at", NOW())
              WHERE "id" = OLD."id";
          ELSE
              UPDATE "tailorings_v2" SET
                "policy_id" = NEW."policy_id",
                "profile_id" = NEW."parent_profile_id",
                "value_overrides" = COALESCE(NEW."value_overrides", '{}'),
                "os_minor_version" = CAST(NULLIF(NEW."os_minor_version", '') AS int),
                "updated_at" = COALESCE(NEW."updated_at", NOW())
              WHERE "id" = OLD."id";
          END IF;

          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_profiles_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_profiles_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          IF OLD."parent_profile_id" IS NOT NULL THEN
              DELETE FROM "tailorings_v2" WHERE "id" = OLD."id";
          END IF;

          RETURN OLD;
      END
      $function$
  SQL

  create_function :v1_rule_results_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_rule_results_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "rule_results_v2" (
            "result",
            "rule_id",
            "test_result_id",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."result",
            NEW."rule_id",
            NEW."test_result_id",
            COALESCE(NEW."created_at", NOW()),
            COALESCE(NEW."updated_at", NOW())
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL

  create_function :v1_rule_results_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_rule_results_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          DELETE FROM "rule_results_v2" WHERE "id" = OLD."id";
          RETURN OLD;
      END
      $function$
  SQL

  create_trigger :v1_benchmarks_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_benchmarks_insert INSTEAD OF INSERT ON public.v1_benchmarks FOR EACH ROW EXECUTE FUNCTION v1_benchmarks_insert()
  SQL

  create_trigger :v1_benchmarks_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_benchmarks_update INSTEAD OF UPDATE ON public.v1_benchmarks FOR EACH ROW EXECUTE FUNCTION v1_benchmarks_update()
  SQL

  create_trigger :v1_policy_hosts_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_policy_hosts_insert INSTEAD OF INSERT ON public.v1_policy_hosts FOR EACH ROW EXECUTE FUNCTION v1_policy_hosts_insert()
  SQL

  create_trigger :v1_policy_hosts_delete, sql_definition: <<-SQL
      CREATE TRIGGER v1_policy_hosts_delete INSTEAD OF DELETE ON public.v1_policy_hosts FOR EACH ROW EXECUTE FUNCTION v1_policy_hosts_delete()
  SQL

  create_trigger :v1_profile_rules_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_profile_rules_insert INSTEAD OF INSERT ON public.v1_profile_rules FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_insert()
  SQL

  create_trigger :v1_profile_rules_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_profile_rules_update INSTEAD OF UPDATE ON public.v1_profile_rules FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_update()
  SQL

  create_trigger :v1_profile_rules_delete, sql_definition: <<-SQL
      CREATE TRIGGER v1_profile_rules_delete INSTEAD OF DELETE ON public.v1_profile_rules FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_delete()
  SQL

  create_trigger :v1_profiles_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_profiles_update INSTEAD OF UPDATE ON public.v1_profiles FOR EACH ROW EXECUTE FUNCTION v1_profiles_update()
  SQL

  create_trigger :v1_profiles_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_profiles_insert INSTEAD OF INSERT ON public.v1_profiles FOR EACH ROW EXECUTE FUNCTION v1_profiles_insert()
  SQL

  create_trigger :v1_profiles_delete, sql_definition: <<-SQL
      CREATE TRIGGER v1_profiles_delete INSTEAD OF DELETE ON public.v1_profiles FOR EACH ROW EXECUTE FUNCTION v1_profiles_delete()
  SQL

  create_trigger :v1_rule_group_relationships_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_group_relationships_update INSTEAD OF UPDATE ON public.v1_rule_group_relationships FOR EACH ROW EXECUTE FUNCTION v1_rule_group_relationships_update()
  SQL

  create_trigger :v1_rule_group_relationships_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_group_relationships_insert INSTEAD OF INSERT ON public.v1_rule_group_relationships FOR EACH ROW EXECUTE FUNCTION v1_rule_group_relationships_insert()
  SQL

  create_trigger :v1_rule_groups_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_groups_update INSTEAD OF UPDATE ON public.v1_rule_groups FOR EACH ROW EXECUTE FUNCTION v1_rule_groups_update()
  SQL

  create_trigger :v1_rule_groups_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_groups_insert INSTEAD OF INSERT ON public.v1_rule_groups FOR EACH ROW EXECUTE FUNCTION v1_rule_groups_insert()
  SQL

  create_trigger :v1_rule_results_delete, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_results_delete INSTEAD OF DELETE ON public.v1_rule_results FOR EACH ROW EXECUTE FUNCTION v1_rule_results_delete()
  SQL

  create_trigger :v1_rule_results_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_results_insert INSTEAD OF INSERT ON public.v1_rule_results FOR EACH ROW EXECUTE FUNCTION v1_rule_results_insert()
  SQL

  create_trigger :v1_rules_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_rules_insert INSTEAD OF INSERT ON public.v1_rules FOR EACH ROW EXECUTE FUNCTION v1_rules_insert()
  SQL

  create_trigger :v1_rules_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_rules_update INSTEAD OF UPDATE ON public.v1_rules FOR EACH ROW EXECUTE FUNCTION v1_rules_update()
  SQL

  create_trigger :v1_test_results_delete, sql_definition: <<-SQL
      CREATE TRIGGER v1_test_results_delete INSTEAD OF DELETE ON public.v1_test_results FOR EACH ROW EXECUTE FUNCTION v1_test_results_delete()
  SQL

  create_trigger :v1_test_results_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_test_results_insert INSTEAD OF INSERT ON public.v1_test_results FOR EACH ROW EXECUTE FUNCTION v1_test_results_insert()
  SQL

  create_trigger :v1_value_definitions_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_value_definitions_insert INSTEAD OF INSERT ON public.v1_value_definitions FOR EACH ROW EXECUTE FUNCTION v1_value_definitions_insert()
  SQL

  create_trigger :v2_test_results_insert, sql_definition: <<-SQL
      CREATE TRIGGER v2_test_results_insert INSTEAD OF INSERT ON public.v2_test_results FOR EACH ROW EXECUTE FUNCTION v2_test_results_insert()
  SQL

  create_trigger :v2_test_results_delete, sql_definition: <<-SQL
      CREATE TRIGGER v2_test_results_delete INSTEAD OF DELETE ON public.v2_test_results FOR EACH ROW EXECUTE FUNCTION v2_test_results_delete()
  SQL
end
