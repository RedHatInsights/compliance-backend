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

ActiveRecord::Schema[8.1].define(version: 2026_07_07_142129) do
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

  create_table "historical_test_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.index ["supported"], name: "index_historical_test_results_on_supported"
    t.index ["system_id", "tailoring_id", "end_time"], name: "index_historical_test_results_v2_on_system_tailoring_end_time", unique: true
    t.index ["system_id"], name: "index_historical_test_results_on_system_id"
    t.index ["tailoring_id", "system_id", "end_time"], name: "index_historical_test_results_v2_for_latest_lookup", order: { end_time: :desc }, include: ["id"]
    t.index ["tailoring_id"], name: "index_historical_test_results_on_tailoring_id"
  end

  create_table "policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "business_objective"
    t.float "compliance_threshold", default: 100.0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.uuid "profile_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_policies_on_account_id"
    t.index ["profile_id"], name: "index_policies_on_profile_id"
  end

  create_table "policy_systems", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.uuid "policy_id", null: false
    t.uuid "system_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["policy_id", "system_id"], name: "index_policy_systems_on_policy_id_and_system_id", unique: true
    t.index ["policy_id"], name: "index_policy_systems_on_policy_id"
    t.index ["system_id"], name: "index_policy_systems_on_system_id"
  end

  create_table "profile_os_minor_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "os_minor_version"
    t.uuid "profile_id"
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_profile_os_minor_versions_on_profile_id"
  end

  create_table "profile_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "profile_id", null: false
    t.uuid "rule_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["profile_id", "rule_id"], name: "index_profile_rules_on_profile_id_and_rule_id", unique: true
    t.index ["profile_id"], name: "index_profile_rules_on_profile_id"
    t.index ["rule_id"], name: "index_profile_rules_on_rule_id"
  end

  create_table "profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.string "ref_id"
    t.uuid "security_guide_id", null: false
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "upstream"
    t.jsonb "value_overrides", default: {}
    t.index ["ref_id", "security_guide_id"], name: "index_profiles_on_ref_id_and_security_guide_id", unique: true
    t.index ["title"], name: "index_profiles_on_title"
    t.index ["upstream"], name: "index_profiles_on_upstream"
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

  create_table "rule_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.index ["ancestry"], name: "index_rule_groups_on_ancestry"
    t.index ["precedence"], name: "index_rule_groups_on_precedence"
    t.index ["ref_id", "security_guide_id"], name: "index_rule_groups_on_ref_id_and_security_guide_id", unique: true
    t.index ["rule_id"], name: "index_rule_groups_on_rule_id", unique: true
    t.index ["security_guide_id"], name: "index_rule_groups_on_security_guide_id"
  end

  create_table "rule_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "result"
    t.uuid "rule_id", null: false
    t.uuid "test_result_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["rule_id"], name: "index_rule_results_on_rule_id"
    t.index ["test_result_id", "result"], name: "index_rule_results_on_test_result_id_and_result"
    t.index ["test_result_id", "rule_id"], name: "index_rule_results_on_test_result_id_and_rule_id", unique: true
    t.index ["test_result_id"], name: "index_rule_results_on_test_result_id"
  end

  create_table "rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.index ["precedence"], name: "index_rules_on_precedence"
    t.index ["ref_id", "security_guide_id"], name: "index_rules_on_ref_id_and_security_guide_id", unique: true
    t.index ["ref_id"], name: "index_rules_on_ref_id"
    t.index ["references"], name: "index_rules_on_references", opclass: :jsonb_path_ops, using: :gin
    t.index ["severity"], name: "index_rules_on_severity"
    t.index ["upstream"], name: "index_rules_on_upstream"
  end

  create_table "security_guides", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description", null: false
    t.integer "os_major_version", null: false
    t.string "package_name"
    t.string "ref_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "version", null: false
    t.index ["ref_id", "version"], name: "index_security_guides_on_ref_id_and_version", unique: true
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

  create_table "tailoring_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.uuid "rule_id", null: false
    t.uuid "tailoring_id", null: false
    t.datetime "updated_at", precision: nil
    t.index ["rule_id"], name: "index_tailoring_rules_on_rule_id"
    t.index ["tailoring_id", "rule_id"], name: "index_tailoring_rules_on_tailoring_id_and_rule_id", unique: true
    t.index ["tailoring_id"], name: "index_tailoring_rules_on_tailoring_id"
  end

  create_table "tailorings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "os_minor_version"
    t.uuid "policy_id", null: false
    t.uuid "profile_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "value_overrides", default: {}
    t.index ["policy_id"], name: "index_tailorings_on_policy_id"
    t.index ["profile_id"], name: "index_tailorings_on_profile_id"
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

  create_table "value_definitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.index ["ref_id", "security_guide_id"], name: "index_value_definitions_on_ref_id_and_security_guide_id", unique: true
    t.index ["security_guide_id"], name: "index_value_definitions_on_security_guide_id"
  end

  add_foreign_key "policies", "accounts"
  add_foreign_key "policies", "profiles"
  add_foreign_key "policy_systems", "policies"
  add_foreign_key "rule_groups", "rules"
  add_foreign_key "rule_groups", "security_guides"
  add_foreign_key "rules", "rule_groups"
  add_foreign_key "tailorings", "policies"
  add_foreign_key "tailorings", "profiles"
  add_foreign_key "value_definitions", "security_guides"

  create_view "report_systems", sql_definition: <<-SQL
      SELECT id,
      policy_id AS report_id,
      system_id
     FROM policy_systems;
  SQL
  create_view "supported_profiles", sql_definition: <<-SQL
      SELECT (array_agg(profiles.id ORDER BY (string_to_array((security_guides.version)::text, '.'::text))::integer[] DESC))[1] AS id,
      (array_agg(profiles.title ORDER BY (string_to_array((security_guides.version)::text, '.'::text))::integer[] DESC))[1] AS title,
      (array_agg(profiles.description ORDER BY (string_to_array((security_guides.version)::text, '.'::text))::integer[] DESC))[1] AS description,
      profiles.ref_id,
      (array_agg(security_guides.id ORDER BY (string_to_array((security_guides.version)::text, '.'::text))::integer[] DESC))[1] AS security_guide_id,
      (array_agg(security_guides.version ORDER BY (string_to_array((security_guides.version)::text, '.'::text))::integer[] DESC))[1] AS security_guide_version,
      security_guides.os_major_version,
      array_agg(DISTINCT profile_os_minor_versions.os_minor_version ORDER BY profile_os_minor_versions.os_minor_version DESC) AS os_minor_versions
     FROM ((profiles
       JOIN security_guides ON ((security_guides.id = profiles.security_guide_id)))
       JOIN profile_os_minor_versions ON ((profile_os_minor_versions.profile_id = profiles.id)))
    GROUP BY profiles.ref_id, security_guides.os_major_version;
  SQL
  create_view "test_results", sql_definition: <<-SQL
      SELECT historical_test_results.id,
      historical_test_results.tailoring_id,
      historical_test_results.report_id,
      historical_test_results.system_id,
      historical_test_results.start_time,
      historical_test_results.end_time,
      historical_test_results.score,
      historical_test_results.supported,
      historical_test_results.failed_rule_count,
      historical_test_results.created_at,
      historical_test_results.updated_at
     FROM (historical_test_results
       JOIN ( SELECT historical_test_results_1.tailoring_id,
              historical_test_results_1.system_id,
              max(historical_test_results_1.end_time) AS end_time
             FROM historical_test_results historical_test_results_1
            GROUP BY historical_test_results_1.tailoring_id, historical_test_results_1.system_id) tr ON (((historical_test_results.tailoring_id = tr.tailoring_id) AND (historical_test_results.system_id = tr.system_id) AND (historical_test_results.end_time = tr.end_time))));
  SQL

  create_function :test_results_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.test_results_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          DELETE FROM "historical_test_results" WHERE "id" = OLD."id";
          RETURN OLD;
      END
      $function$
  SQL

  create_function :test_results_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.test_results_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "historical_test_results" (
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

  create_trigger :test_results_delete, sql_definition: <<-SQL
      CREATE TRIGGER test_results_delete INSTEAD OF DELETE ON public.test_results FOR EACH ROW EXECUTE FUNCTION test_results_delete()
  SQL

  create_trigger :test_results_insert, sql_definition: <<-SQL
      CREATE TRIGGER test_results_insert INSTEAD OF INSERT ON public.test_results FOR EACH ROW EXECUTE FUNCTION test_results_insert()
  SQL
end
