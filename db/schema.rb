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

ActiveRecord::Schema[8.0].define(version: 2026_02_11_120320) do
  create_schema "inventory"

  # These are extensions that must be enabled in order to support this database
  enable_extension "dblink"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "org_id", null: false
    t.index ["org_id"], name: "index_accounts_on_org_id", unique: true
  end

  create_table "benchmarks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "version", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "package_name"
    t.index ["ref_id", "version"], name: "index_benchmarks_on_ref_id_and_version", unique: true
  end

  create_table "business_objectives", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["title"], name: "index_business_objectives_on_title"
  end

  create_table "canonical_profiles_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "ref_id"
    t.string "description"
    t.uuid "security_guide_id", null: false
    t.boolean "upstream"
    t.jsonb "value_overrides", default: {}
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ref_id", "security_guide_id"], name: "index_canonical_profiles_v2_on_ref_id_and_security_guide_id", unique: true
    t.index ["title"], name: "index_canonical_profiles_v2_on_title"
    t.index ["upstream"], name: "index_canonical_profiles_v2_on_upstream"
  end

  create_table "fixes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "strategy"
    t.string "disruption"
    t.string "complexity"
    t.string "system"
    t.text "text"
    t.uuid "rule_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["rule_id", "system"], name: "index_fixes_on_rule_id_and_system", unique: true
    t.index ["rule_id"], name: "index_fixes_on_rule_id"
    t.index ["system"], name: "index_fixes_on_system"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "business_objective_id"
    t.float "compliance_threshold", default: 100.0
    t.string "name"
    t.string "description"
    t.uuid "account_id"
    t.integer "total_host_count", default: 0, null: false
    t.integer "test_result_host_count", default: 0, null: false
    t.integer "compliant_host_count", default: 0, null: false
    t.integer "unsupported_host_count", default: 0, null: false
    t.uuid "profile_id"
    t.index ["account_id"], name: "index_policies_on_account_id"
    t.index ["business_objective_id"], name: "index_policies_on_business_objective_id"
    t.index ["profile_id"], name: "index_policies_on_profile_id"
  end

  create_table "policy_hosts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "policy_id", null: false
    t.uuid "host_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["host_id"], name: "index_policy_hosts_on_host_id"
    t.index ["policy_id", "host_id"], name: "index_policy_hosts_on_policy_id_and_host_id", unique: true
    t.index ["policy_id"], name: "index_policy_hosts_on_policy_id"
  end

  create_table "profile_os_minor_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "profile_id"
    t.integer "os_minor_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_profile_os_minor_versions_on_profile_id"
  end

  create_table "profile_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "rule_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["profile_id", "rule_id"], name: "index_profile_rules_on_profile_id_and_rule_id", unique: true
    t.index ["profile_id"], name: "index_profile_rules_on_profile_id"
    t.index ["rule_id"], name: "index_profile_rules_on_rule_id"
  end

  create_table "profile_rules_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "rule_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["profile_id", "rule_id"], name: "index_profile_rules_v2_on_profile_id_and_rule_id", unique: true
    t.index ["profile_id"], name: "index_profile_rules_v2_on_profile_id"
    t.index ["rule_id"], name: "index_profile_rules_v2_on_rule_id"
  end

  create_table "profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "ref_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "description"
    t.uuid "account_id"
    t.uuid "benchmark_id", null: false
    t.uuid "parent_profile_id"
    t.boolean "external", default: false, null: false
    t.uuid "policy_id"
    t.string "os_minor_version", default: "", null: false
    t.decimal "score"
    t.boolean "upstream"
    t.jsonb "value_overrides", default: {}
    t.index ["account_id"], name: "index_profiles_on_account_id"
    t.index ["external"], name: "index_profiles_on_external"
    t.index ["name"], name: "index_profiles_on_name"
    t.index ["os_minor_version"], name: "index_profiles_on_os_minor_version"
    t.index ["parent_profile_id"], name: "index_profiles_on_parent_profile_id"
    t.index ["policy_id"], name: "index_profiles_on_policy_id"
    t.index ["ref_id", "account_id", "benchmark_id", "os_minor_version", "policy_id"], name: "uniqueness", unique: true
    t.index ["ref_id", "benchmark_id"], name: "index_profiles_on_ref_id_and_benchmark_id", unique: true, where: "(parent_profile_id IS NULL)"
    t.index ["upstream"], name: "index_profiles_on_upstream"
  end

  create_table "revisions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "revision", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_revisions_on_name", unique: true
  end

  create_table "rule_group_relationships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "left_type"
    t.uuid "left_id"
    t.string "right_type"
    t.uuid "right_id"
    t.string "relationship"
    t.index ["left_id", "right_id", "right_type", "left_type", "relationship"], name: "index_rule_group_relationships_unique", unique: true
    t.index ["left_type", "left_id"], name: "index_rule_group_relationships_on_left"
    t.index ["right_type", "right_id"], name: "index_rule_group_relationships_on_right"
  end

  create_table "rule_group_relationships_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "left_type"
    t.uuid "left_id", null: false
    t.string "right_type"
    t.uuid "right_id", null: false
    t.string "relationship", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["left_id", "right_id", "right_type", "left_type", "relationship"], name: "unique_index_rule_group_relationships_v2", unique: true
    t.index ["left_type", "left_id"], name: "index_rule_group_relationships_v2_on_left"
    t.index ["right_type", "right_id"], name: "index_rule_group_relationships_v2_on_right"
  end

  create_table "rule_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.string "title"
    t.text "description"
    t.text "rationale"
    t.string "ancestry"
    t.uuid "benchmark_id", null: false
    t.uuid "rule_id"
    t.integer "precedence"
    t.index ["ancestry"], name: "index_rule_groups_on_ancestry"
    t.index ["benchmark_id"], name: "index_rule_groups_on_benchmark_id"
    t.index ["precedence"], name: "index_rule_groups_on_precedence"
    t.index ["ref_id", "benchmark_id"], name: "index_rule_groups_on_ref_id_and_benchmark_id", unique: true
    t.index ["rule_id"], name: "index_rule_groups_on_rule_id", unique: true
  end

  create_table "rule_groups_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.string "title"
    t.text "description"
    t.text "rationale"
    t.string "ancestry"
    t.uuid "security_guide_id", null: false
    t.uuid "rule_id"
    t.integer "precedence"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ancestry"], name: "index_rule_groups_v2_on_ancestry"
    t.index ["precedence"], name: "index_rule_groups_v2_on_precedence"
    t.index ["ref_id", "security_guide_id"], name: "index_rule_groups_v2_on_ref_id_and_security_guide_id", unique: true
    t.index ["rule_id"], name: "index_rule_groups_v2_on_rule_id", unique: true
    t.index ["security_guide_id"], name: "index_rule_groups_v2_on_security_guide_id"
  end

  create_table "rule_references_containers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "rule_id", null: false
    t.jsonb "rule_references"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rule_id"], name: "index_rule_references_containers_on_rule_id", unique: true
    t.index ["rule_references"], name: "index_rule_references_containers_on_rule_references", opclass: :jsonb_path_ops, using: :gin
  end

  create_table "rule_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "host_id"
    t.uuid "rule_id"
    t.string "result"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "test_result_id"
    t.index ["host_id", "rule_id", "test_result_id"], name: "index_rule_results_on_host_id_and_rule_id_and_test_result_id", unique: true
    t.index ["host_id"], name: "index_rule_results_on_host_id"
    t.index ["rule_id"], name: "index_rule_results_on_rule_id"
    t.index ["test_result_id"], name: "index_rule_results_on_test_result_id"
  end

  create_table "rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.boolean "supported"
    t.string "title"
    t.string "severity"
    t.text "description"
    t.text "rationale"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "slug"
    t.boolean "remediation_available", default: false, null: false
    t.uuid "benchmark_id", null: false
    t.boolean "upstream", default: true, null: false
    t.integer "precedence"
    t.uuid "rule_group_id"
    t.uuid "value_checks", default: [], array: true
    t.jsonb "identifier"
    t.index "((identifier -> 'label'::text))", name: "index_rules_on_identifier_labels", using: :gin
    t.index ["precedence"], name: "index_rules_on_precedence"
    t.index ["ref_id", "benchmark_id"], name: "index_rules_on_ref_id_and_benchmark_id", unique: true
    t.index ["ref_id"], name: "index_rules_on_ref_id"
    t.index ["slug", "benchmark_id"], name: "index_rules_on_slug_and_benchmark_id", unique: true
    t.index ["upstream"], name: "index_rules_on_upstream"
  end

  create_table "rules_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.string "title"
    t.string "severity"
    t.text "description"
    t.text "rationale"
    t.boolean "remediation_available", default: false, null: false
    t.uuid "security_guide_id", null: false
    t.boolean "upstream", default: false, null: false
    t.integer "precedence"
    t.uuid "rule_group_id"
    t.uuid "value_checks", default: [], array: true
    t.jsonb "identifier"
    t.jsonb "references"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index "((identifier -> 'label'::text))", name: "index_rules_v2_on_identifier_labels", using: :gin
    t.index ["precedence"], name: "index_rules_v2_on_precedence"
    t.index ["ref_id", "security_guide_id"], name: "index_rules_v2_on_ref_id_and_security_guide_id", unique: true
    t.index ["ref_id"], name: "index_rules_v2_on_ref_id"
    t.index ["references"], name: "index_rules_v2_on_references", opclass: :jsonb_path_ops, using: :gin
    t.index ["upstream"], name: "index_rules_v2_on_upstream"
  end

  create_table "security_guides_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id", null: false
    t.integer "os_major_version", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "version", null: false
    t.string "package_name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ref_id", "version"], name: "index_security_guides_v2_on_ref_id_and_version", unique: true
  end

  create_table "test_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.decimal "score"
    t.uuid "profile_id"
    t.uuid "host_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "supported", default: true
    t.integer "failed_rule_count", default: 0, null: false
    t.index ["host_id", "profile_id", "end_time"], name: "index_test_results_on_host_id_and_profile_id_and_end_time", unique: true
    t.index ["host_id"], name: "index_test_results_on_host_id"
    t.index ["profile_id"], name: "index_test_results_on_profile_id"
    t.index ["supported"], name: "index_test_results_on_supported"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "redhat_id"
    t.string "redhat_org_id"
    t.string "lang"
    t.string "locale"
    t.string "username"
    t.boolean "internal"
    t.boolean "active"
    t.boolean "org_admin"
    t.uuid "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  create_table "value_definitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.string "title"
    t.text "description"
    t.string "value_type"
    t.string "default_value"
    t.decimal "lower_bound"
    t.decimal "upper_bound"
    t.uuid "benchmark_id", null: false
    t.index ["benchmark_id"], name: "index_value_definitions_on_benchmark_id"
    t.index ["ref_id", "benchmark_id"], name: "index_value_definitions_on_ref_id_and_benchmark_id", unique: true
  end

  create_table "value_definitions_v2", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.string "title"
    t.text "description"
    t.string "value_type"
    t.string "default_value"
    t.decimal "lower_bound"
    t.decimal "upper_bound"
    t.uuid "security_guide_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ref_id", "security_guide_id"], name: "index_value_definitions_v2_on_ref_id_and_security_guide_id", unique: true
    t.index ["security_guide_id"], name: "index_value_definitions_v2_on_security_guide_id"
  end

  add_foreign_key "policies", "accounts"
  add_foreign_key "policies", "business_objectives"
  add_foreign_key "policies", "canonical_profiles_v2", column: "profile_id"
  add_foreign_key "policy_hosts", "policies"
  add_foreign_key "profiles", "canonical_profiles_v2", column: "parent_profile_id"
  add_foreign_key "profiles", "policies"
  add_foreign_key "rule_groups_v2", "rules_v2", column: "rule_id"
  add_foreign_key "rule_groups_v2", "security_guides_v2", column: "security_guide_id"
  add_foreign_key "rules_v2", "rule_groups_v2", column: "rule_group_id"
  add_foreign_key "value_definitions_v2", "security_guides_v2", column: "security_guide_id"
  create_view "canonical_profiles", sql_definition: <<-SQL
      SELECT profiles.id,
      profiles.name AS title,
      profiles.ref_id,
      profiles.created_at,
      profiles.updated_at,
      profiles.description,
      profiles.benchmark_id AS security_guide_id,
      profiles.upstream,
      profiles.value_overrides
     FROM profiles
    WHERE (profiles.parent_profile_id IS NULL);
  SQL
  create_view "v2_value_definitions", sql_definition: <<-SQL
      SELECT value_definitions.id,
      value_definitions.ref_id,
      value_definitions.title,
      value_definitions.description,
      value_definitions.value_type,
      value_definitions.default_value,
      value_definitions.lower_bound,
      value_definitions.upper_bound,
      value_definitions.benchmark_id AS security_guide_id
     FROM value_definitions;
  SQL
  create_view "tailorings", sql_definition: <<-SQL
      SELECT profiles.id,
      profiles.policy_id,
      profiles.parent_profile_id AS profile_id,
      profiles.value_overrides,
      (NULLIF((profiles.os_minor_version)::text, ''::text))::integer AS os_minor_version,
      profiles.created_at,
      profiles.updated_at
     FROM profiles
    WHERE (parent_profile_id IS NOT NULL);
  SQL
  create_view "security_guides", sql_definition: <<-SQL
      SELECT benchmarks.id,
      benchmarks.ref_id,
      (regexp_replace((benchmarks.ref_id)::text, '.+RHEL-(\\d+)$'::text, '\\1'::text))::integer AS os_major_version,
      benchmarks.title,
      benchmarks.description,
      benchmarks.version,
      benchmarks.created_at,
      benchmarks.updated_at,
      benchmarks.package_name
     FROM benchmarks;
  SQL
  create_view "v2_rule_groups", sql_definition: <<-SQL
      SELECT rule_groups.id,
      rule_groups.ref_id,
      rule_groups.title,
      rule_groups.description,
      rule_groups.rationale,
      rule_groups.ancestry,
      rule_groups.benchmark_id AS security_guide_id,
      rule_groups.rule_id,
      rule_groups.precedence
     FROM rule_groups;
  SQL
  create_view "policy_systems", sql_definition: <<-SQL
      SELECT policy_hosts.id,
      policy_hosts.policy_id,
      policy_hosts.host_id AS system_id
     FROM policy_hosts;
  SQL
  create_view "v2_policies", sql_definition: <<-SQL
      SELECT policies.id,
      policies.name AS title,
      policies.description,
      policies.compliance_threshold,
      business_objectives.title AS business_objective,
      COALESCE(sq.total_system_count, (0)::bigint) AS total_system_count,
      policies.profile_id,
      policies.account_id
     FROM ((policies
       LEFT JOIN business_objectives ON ((business_objectives.id = policies.business_objective_id)))
       LEFT JOIN ( SELECT count(policy_hosts.host_id) AS total_system_count,
              policy_hosts.policy_id
             FROM policy_hosts
            GROUP BY policy_hosts.policy_id) sq ON ((sq.policy_id = policies.id)));
  SQL
  create_view "tailoring_rules", sql_definition: <<-SQL
      SELECT profile_rules.id,
      profile_rules.profile_id AS tailoring_id,
      profile_rules.rule_id
     FROM profile_rules;
  SQL
  create_view "v2_rules", sql_definition: <<-SQL
      SELECT rules.id,
      rules.ref_id,
      rules.title,
      rules.severity,
      rules.description,
      rules.rationale,
      rules.created_at,
      rules.updated_at,
      rules.remediation_available,
      rules.benchmark_id AS security_guide_id,
      rules.upstream,
      rules.precedence,
      rules.rule_group_id,
      rules.value_checks,
      rules.identifier,
      rule_references_containers.rule_references AS "references"
     FROM (rules
       LEFT JOIN rule_references_containers ON ((rule_references_containers.rule_id = rules.id)));
  SQL
  create_view "report_systems", sql_definition: <<-SQL
      SELECT policy_hosts.id,
      policy_hosts.policy_id AS report_id,
      policy_hosts.host_id AS system_id
     FROM policy_hosts;
  SQL
  create_view "historical_test_results", sql_definition: <<-SQL
      SELECT test_results.id,
      test_results.profile_id AS tailoring_id,
      profiles.policy_id AS report_id,
      test_results.host_id AS system_id,
      test_results.start_time,
      test_results.end_time,
      test_results.score,
      test_results.supported,
      test_results.failed_rule_count,
      test_results.created_at,
      test_results.updated_at
     FROM (test_results
       JOIN profiles ON ((profiles.id = test_results.profile_id)));
  SQL
  create_view "v2_test_results", sql_definition: <<-SQL
      SELECT test_results.id,
      test_results.profile_id AS tailoring_id,
      profiles.policy_id AS report_id,
      test_results.host_id AS system_id,
      test_results.start_time,
      test_results.end_time,
      test_results.score,
      test_results.supported,
      test_results.failed_rule_count,
      test_results.created_at,
      test_results.updated_at
     FROM ((test_results
       JOIN profiles ON ((profiles.id = test_results.profile_id)))
       JOIN ( SELECT test_results_1.profile_id,
              test_results_1.host_id,
              max(test_results_1.end_time) AS end_time
             FROM test_results test_results_1
            GROUP BY test_results_1.profile_id, test_results_1.host_id) tr ON (((test_results.profile_id = tr.profile_id) AND (test_results.host_id = tr.host_id) AND (test_results.end_time = tr.end_time))));
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
   SELECT profiles.id,
      profiles.name,
      profiles.ref_id,
      profiles.created_at,
      profiles.updated_at,
      profiles.description,
      profiles.account_id,
      profiles.benchmark_id,
      profiles.parent_profile_id,
      profiles.external,
      profiles.policy_id,
      profiles.os_minor_version,
      profiles.score,
      profiles.upstream,
      profiles.value_overrides
     FROM profiles
    WHERE (profiles.parent_profile_id IS NOT NULL);
  SQL
  create_view "v1_benchmarks", sql_definition: <<-SQL
      SELECT security_guides_v2.id,
      security_guides_v2.ref_id,
      security_guides_v2.title,
      security_guides_v2.description,
      security_guides_v2.version,
      security_guides_v2.created_at,
      security_guides_v2.updated_at,
      security_guides_v2.package_name
     FROM security_guides_v2;
  SQL
  create_view "v1_rules", sql_definition: <<-SQL
      SELECT rules_v2.id,
      rules_v2.ref_id,
      NULL::boolean AS supported,
      rules_v2.title,
      rules_v2.severity,
      rules_v2.description,
      rules_v2.rationale,
      rules_v2.created_at,
      rules_v2.updated_at,
      lower(replace((rules_v2.ref_id)::text, '.'::text, '-'::text)) AS slug,
      rules_v2.remediation_available,
      rules_v2.security_guide_id AS benchmark_id,
      rules_v2.upstream,
      rules_v2.precedence,
      rules_v2.rule_group_id,
      rules_v2.value_checks,
      rules_v2.identifier
     FROM rules_v2;
  SQL
  create_view "v1_value_definitions", sql_definition: <<-SQL
      SELECT value_definitions_v2.id,
      value_definitions_v2.ref_id,
      value_definitions_v2.title,
      value_definitions_v2.description,
      value_definitions_v2.value_type,
      value_definitions_v2.default_value,
      value_definitions_v2.lower_bound,
      value_definitions_v2.upper_bound,
      value_definitions_v2.security_guide_id AS benchmark_id,
      value_definitions_v2.created_at,
      value_definitions_v2.updated_at
     FROM value_definitions_v2;
  SQL
  create_view "v1_rule_groups", sql_definition: <<-SQL
      SELECT rule_groups_v2.id,
      rule_groups_v2.ref_id,
      rule_groups_v2.title,
      rule_groups_v2.description,
      rule_groups_v2.rationale,
      rule_groups_v2.ancestry,
      rule_groups_v2.security_guide_id AS benchmark_id,
      rule_groups_v2.rule_id,
      rule_groups_v2.precedence,
      rule_groups_v2.created_at,
      rule_groups_v2.updated_at
     FROM rule_groups_v2;
  SQL
  create_view "v1_profile_rules", sql_definition: <<-SQL
      SELECT profile_rules_v2.id,
      profile_rules_v2.profile_id,
      profile_rules_v2.rule_id,
      profile_rules_v2.created_at,
      profile_rules_v2.updated_at
     FROM profile_rules_v2
  UNION ALL
   SELECT profile_rules.id,
      profile_rules.profile_id,
      profile_rules.rule_id,
      profile_rules.created_at,
      profile_rules.updated_at
     FROM (profile_rules
       JOIN profiles ON ((profile_rules.profile_id = profiles.id)))
    WHERE (profiles.parent_profile_id IS NOT NULL);
  SQL
  create_view "v1_rule_group_relationships", sql_definition: <<-SQL
      SELECT rule_group_relationships_v2.id,
      rule_group_relationships_v2.left_type,
      rule_group_relationships_v2.left_id,
      rule_group_relationships_v2.right_type,
      rule_group_relationships_v2.right_id,
      rule_group_relationships_v2.relationship,
      rule_group_relationships_v2.created_at,
      rule_group_relationships_v2.updated_at
     FROM rule_group_relationships_v2;
  SQL
  create_function :v2_policies_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_policies_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE bo_id uuid;
      DECLARE result_id uuid;
      BEGIN
          -- Insert a new business objective record if the business_objective field is
          -- set to a value and return with its ID.
          INSERT INTO "business_objectives" ("title", "created_at", "updated_at")
          SELECT NEW."business_objective", NOW(), NOW()
          WHERE NEW."business_objective" IS NOT NULL RETURNING "id" INTO "bo_id";

          INSERT INTO "policies" (
            "name",
            "description",
            "compliance_threshold",
            "business_objective_id",
            "profile_id",
            "account_id"
          ) VALUES (
            NEW."title",
            NEW."description",
            NEW."compliance_threshold",
            "bo_id",
            NEW."profile_id",
            NEW."account_id"
          ) RETURNING "id" INTO "result_id";

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL
  create_function :v2_policies_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_policies_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE bo_id uuid;
      BEGIN
        DELETE FROM "policies" WHERE "id" = OLD."id" RETURNING "business_objective_id" INTO "bo_id";
        -- Delete any remaining business objectives associated with the policy of no other policies use it
        DELETE FROM "business_objectives" WHERE "id" = "bo_id" AND (SELECT COUNT("id") FROM "policies" WHERE "business_objectives"."id" = "bo_id") = 0;
      RETURN OLD;
      END
      $function$
  SQL
  create_function :v2_policies_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_policies_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE "bo_id" uuid;
      BEGIN
          -- Create a new business objective record if the apropriate field is set and there is no
          -- existing business objective already assigned to the policy and return with its ID.
          INSERT INTO "business_objectives" ("title", "created_at", "updated_at")
          SELECT NEW."business_objective", NOW(), NOW() FROM "policies" WHERE
            NEW."business_objective" IS NOT NULL AND
            "policies"."business_objective_id" IS NULL AND
            "policies"."id" = OLD."id"
          RETURNING "id" INTO "bo_id";

          -- If the previous insertion was successful, there is nothing to update, otherwise try to
          -- update any existing business objective assigned to the policy and return with its ID.
          IF "bo_id" IS NULL THEN
            UPDATE "business_objectives" SET "title" = NEW."business_objective", "updated_at" = NOW()
            FROM "policies" WHERE
              "policies"."business_objective_id" = "business_objectives"."id" AND
              "policies"."id" = OLD."id"
            RETURNING "business_objectives"."id" INTO "bo_id";
          END IF;

          -- Update the policy itself, use the ID of the business objective from the previous two queries,
          -- if the business_objective field is set to NULL, remove the link between the two tables.
          UPDATE "policies" SET
            "name" = NEW."title",
            "description" = NEW."description",
            "compliance_threshold" = NEW."compliance_threshold",
            "business_objective_id" = CASE WHEN NEW."business_objective" IS NULL THEN NULL ELSE "bo_id" END
          WHERE "id" = OLD."id";

          -- If the business_objective field is set to NULL, delete its record in the business objectives
          -- table using the ID retrieved during the second query.
          DELETE FROM "business_objectives" USING "policies"
          WHERE NEW."business_objective" IS NULL AND "business_objectives"."id" = "bo_id";

          RETURN NEW;
      END
      $function$
  SQL
  create_function :v2_rules_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_rules_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "rules" (
            "ref_id",
            "slug",
            "title",
            "severity",
            "description",
            "rationale",
            "created_at",
            "updated_at",
            "remediation_available",
            "benchmark_id",
            "upstream",
            "precedence",
            "rule_group_id",
            "value_checks",
            "identifier"
          ) VALUES (
            NEW."ref_id",
            LOWER(REGEXP_REPLACE(NEW."ref_id", '\.', '-', 'g')),
            NEW."title",
            NEW."severity",
            NEW."description",
            NEW."rationale",
            NEW."created_at",
            NEW."updated_at",
            NEW."remediation_available",
            NEW."security_guide_id",
            NEW."upstream",
            NEW."precedence",
            NEW."rule_group_id",
            NEW."value_checks",
            NEW."identifier"
          ) RETURNING "id" INTO "result_id";

          -- Insert a new rule reference record separately
          INSERT INTO "rule_references_containers" ("rule_references", "rule_id", "created_at", "updated_at")
          SELECT NEW."references", "result_id", NOW(), NOW();

          NEW."id" := "result_id";
          RETURN NEW;
      END
      $function$
  SQL
  create_function :v2_rules_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_rules_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          -- Update the rule reference record separately
          UPDATE "rule_references_containers" SET "rule_references" = NEW."references" WHERE "rule_id" = OLD."id";

          UPDATE "rules" SET
            "ref_id" = NEW."ref_id",
            "title" = NEW."title",
            "severity" = NEW."severity",
            "description" = NEW."description",
            "rationale" = NEW."rationale",
            "created_at" = NEW."created_at",
            "updated_at" = NEW."updated_at",
            "remediation_available" = NEW."remediation_available",
            "benchmark_id" = NEW."security_guide_id",
            "upstream" = NEW."upstream",
            "precedence" = NEW."precedence",
            "rule_group_id" = NEW."rule_group_id",
            "value_checks" = NEW."value_checks",
            "identifier" = NEW."identifier"
          WHERE "id" = OLD."id";

          RETURN NEW;
      END
      $function$
  SQL
  create_function :v2_rules_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_rules_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
        -- Delete the rule reference record separately
        DELETE FROM "rule_references_containers" WHERE "rule_id" = OLD."id";
        DELETE FROM "rules" WHERE "id" = OLD."id";
      RETURN OLD;
      END
      $function$
  SQL
  create_function :v2_test_results_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v2_test_results_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN
          INSERT INTO "test_results" (
            "profile_id",
            "host_id",
            "start_time",
            "end_time",
            "score",
            "supported",
            "failed_rule_count",
            "created_at",
            "updated_at"
          ) VALUES (
            NEW."tailoring_id",
            NEW."system_id",
            NEW."start_time",
            NEW."end_time",
            NEW."score",
            NEW."supported",
            COALESCE(NEW."failed_rule_count", 0),
            NEW."created_at",
            NEW."updated_at"
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
        -- Delete the v2_test_result records belonging to report
        DELETE FROM "test_results" WHERE "id" = OLD."id";
      RETURN OLD;
      END
      $function$
  SQL
  create_function :tailorings_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.tailorings_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      DECLARE external boolean;
      BEGIN

      -- Look up if there's at least one existing profile under this policy
      -- and set the `external` flag to false or true accordingly
      SELECT CASE WHEN COUNT("id") = 0 THEN FALSE ELSE TRUE END INTO "external"
      FROM "profiles" WHERE "profiles"."policy_id" = NEW."policy_id" LIMIT 1;

      INSERT INTO "profiles" (
        "name",
        "ref_id",
        "policy_id",
        "account_id",
        "parent_profile_id",
        "benchmark_id",
        "os_minor_version",
        "value_overrides",
        "external",
        "created_at",
        "updated_at"
      ) SELECT
        "canonical_profiles_v2"."title",
        "canonical_profiles_v2"."ref_id",
        NEW."policy_id",
        "policies"."account_id",
        NEW."profile_id",
        "canonical_profiles_v2"."security_guide_id",
        CAST(NEW."os_minor_version" AS text),
        NEW."value_overrides",
        "external",
        NEW."created_at",
        NEW."updated_at"
      FROM "policies"
      INNER JOIN "canonical_profiles_v2" ON "canonical_profiles_v2"."id" = "policies"."profile_id"
      WHERE "policies"."id" = NEW."policy_id" RETURNING "id" INTO "result_id";

      NEW."id" := "result_id";
      RETURN NEW;

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
              INSERT INTO "profiles" (
                "name",
                "ref_id",
                "description",
                "account_id",
                "benchmark_id",
                "parent_profile_id",
                "external",
                "policy_id",
                "os_minor_version",
                "score",
                "upstream",
                "value_overrides",
                "created_at",
                "updated_at"
              ) VALUES (
                NEW."name",
                NEW."ref_id",
                NEW."description",
                NEW."account_id",
                NEW."benchmark_id",
                NEW."parent_profile_id",
                COALESCE(NEW."external", FALSE),
                NEW."policy_id",
                COALESCE(NEW."os_minor_version", ''),
                NEW."score",
                COALESCE(NEW."upstream", FALSE),
                COALESCE(NEW."value_overrides", '{}'),
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
              UPDATE "profiles" SET
                "name" = NEW."name",
                "ref_id" = NEW."ref_id",
                "description" = NEW."description",
                "account_id" = NEW."account_id",
                "benchmark_id" = NEW."benchmark_id",
                "parent_profile_id" = NEW."parent_profile_id",
                "external" = COALESCE(NEW."external", FALSE),
                "policy_id" = NEW."policy_id",
                "os_minor_version" = COALESCE(NEW."os_minor_version", ''),
                "score" = NEW."score",
                "upstream" = COALESCE(NEW."upstream", FALSE),
                "value_overrides" = COALESCE(NEW."value_overrides", '{}'),
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
              DELETE FROM "profiles" WHERE "id" = OLD."id";
          END IF;

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
  create_function :v1_profile_rules_delete, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.v1_profile_rules_delete()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE
          is_tailoring boolean;
      BEGIN
          SELECT EXISTS(
              SELECT 1 FROM "profiles"
              WHERE "id" = OLD."profile_id"
              AND "parent_profile_id" IS NOT NULL
          ) INTO is_tailoring;

          IF is_tailoring THEN
              DELETE FROM "profile_rules" WHERE "id" = OLD."id";
          ELSE
              DELETE FROM "profile_rules_v2" WHERE "id" = OLD."id";
          END IF;

          RETURN OLD;
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
              SELECT 1 FROM "profiles"
              WHERE "id" = NEW."profile_id"
              AND "parent_profile_id" IS NOT NULL
          ) INTO is_tailoring;

          IF is_tailoring THEN
              INSERT INTO "profile_rules" (
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
              SELECT 1 FROM "profiles"
              WHERE "id" = NEW."profile_id"
              AND "parent_profile_id" IS NOT NULL
          ) INTO is_tailoring;

          IF is_tailoring THEN
              UPDATE "profile_rules" SET
                "profile_id" = NEW."profile_id",
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


  create_trigger :tailorings_insert, sql_definition: <<-SQL
      CREATE TRIGGER tailorings_insert INSTEAD OF INSERT ON public.tailorings FOR EACH ROW EXECUTE FUNCTION tailorings_insert()
  SQL
  create_trigger :v2_policies_insert, sql_definition: <<-SQL
      CREATE TRIGGER v2_policies_insert INSTEAD OF INSERT ON public.v2_policies FOR EACH ROW EXECUTE FUNCTION v2_policies_insert()
  SQL
  create_trigger :v2_policies_delete, sql_definition: <<-SQL
      CREATE TRIGGER v2_policies_delete INSTEAD OF DELETE ON public.v2_policies FOR EACH ROW EXECUTE FUNCTION v2_policies_delete()
  SQL
  create_trigger :v2_policies_update, sql_definition: <<-SQL
      CREATE TRIGGER v2_policies_update INSTEAD OF UPDATE ON public.v2_policies FOR EACH ROW EXECUTE FUNCTION v2_policies_update()
  SQL
  create_trigger :v2_rules_insert, sql_definition: <<-SQL
      CREATE TRIGGER v2_rules_insert INSTEAD OF INSERT ON public.v2_rules FOR EACH ROW EXECUTE FUNCTION v2_rules_insert()
  SQL
  create_trigger :v2_rules_delete, sql_definition: <<-SQL
      CREATE TRIGGER v2_rules_delete INSTEAD OF DELETE ON public.v2_rules FOR EACH ROW EXECUTE FUNCTION v2_rules_delete()
  SQL
  create_trigger :v2_rules_update, sql_definition: <<-SQL
      CREATE TRIGGER v2_rules_update INSTEAD OF UPDATE ON public.v2_rules FOR EACH ROW EXECUTE FUNCTION v2_rules_update()
  SQL
  create_trigger :historical_test_results_delete, sql_definition: <<-SQL
      CREATE TRIGGER historical_test_results_delete INSTEAD OF DELETE ON public.historical_test_results FOR EACH ROW EXECUTE FUNCTION v2_test_results_delete()
  SQL
  create_trigger :v2_test_results_insert, sql_definition: <<-SQL
      CREATE TRIGGER v2_test_results_insert INSTEAD OF INSERT ON public.v2_test_results FOR EACH ROW EXECUTE FUNCTION v2_test_results_insert()
  SQL
  create_trigger :v2_test_results_delete, sql_definition: <<-SQL
      CREATE TRIGGER v2_test_results_delete INSTEAD OF DELETE ON public.v2_test_results FOR EACH ROW EXECUTE FUNCTION v2_test_results_delete()
  SQL
  create_trigger :v1_profiles_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_profiles_insert INSTEAD OF INSERT ON public.v1_profiles FOR EACH ROW EXECUTE FUNCTION v1_profiles_insert()
  SQL
  create_trigger :v1_profiles_delete, sql_definition: <<-SQL
      CREATE TRIGGER v1_profiles_delete INSTEAD OF DELETE ON public.v1_profiles FOR EACH ROW EXECUTE FUNCTION v1_profiles_delete()
  SQL
  create_trigger :v1_profiles_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_profiles_update INSTEAD OF UPDATE ON public.v1_profiles FOR EACH ROW EXECUTE FUNCTION v1_profiles_update()
  SQL
  create_trigger :v1_benchmarks_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_benchmarks_update INSTEAD OF UPDATE ON public.v1_benchmarks FOR EACH ROW EXECUTE FUNCTION v1_benchmarks_update()
  SQL
  create_trigger :v1_benchmarks_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_benchmarks_insert INSTEAD OF INSERT ON public.v1_benchmarks FOR EACH ROW EXECUTE FUNCTION v1_benchmarks_insert()
  SQL
  create_trigger :v1_rules_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_rules_update INSTEAD OF UPDATE ON public.v1_rules FOR EACH ROW EXECUTE FUNCTION v1_rules_update()
  SQL
  create_trigger :v1_rules_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_rules_insert INSTEAD OF INSERT ON public.v1_rules FOR EACH ROW EXECUTE FUNCTION v1_rules_insert()
  SQL
  create_trigger :v1_value_definitions_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_value_definitions_insert INSTEAD OF INSERT ON public.v1_value_definitions FOR EACH ROW EXECUTE FUNCTION v1_value_definitions_insert()
  SQL
  create_trigger :v1_rule_groups_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_groups_update INSTEAD OF UPDATE ON public.v1_rule_groups FOR EACH ROW EXECUTE FUNCTION v1_rule_groups_update()
  SQL
  create_trigger :v1_rule_groups_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_groups_insert INSTEAD OF INSERT ON public.v1_rule_groups FOR EACH ROW EXECUTE FUNCTION v1_rule_groups_insert()
  SQL
  create_trigger :v1_rule_group_relationships_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_group_relationships_update INSTEAD OF UPDATE ON public.v1_rule_group_relationships FOR EACH ROW EXECUTE FUNCTION v1_rule_group_relationships_update()
  SQL
  create_trigger :v1_rule_group_relationships_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_rule_group_relationships_insert INSTEAD OF INSERT ON public.v1_rule_group_relationships FOR EACH ROW EXECUTE FUNCTION v1_rule_group_relationships_insert()
  SQL
  create_trigger :v1_profile_rules_delete, sql_definition: <<-SQL
      CREATE TRIGGER v1_profile_rules_delete INSTEAD OF DELETE ON public.v1_profile_rules FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_delete()
  SQL
  create_trigger :v1_profile_rules_insert, sql_definition: <<-SQL
      CREATE TRIGGER v1_profile_rules_insert INSTEAD OF INSERT ON public.v1_profile_rules FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_insert()
  SQL
  create_trigger :v1_profile_rules_update, sql_definition: <<-SQL
      CREATE TRIGGER v1_profile_rules_update INSTEAD OF UPDATE ON public.v1_profile_rules FOR EACH ROW EXECUTE FUNCTION v1_profile_rules_update()
  SQL
end
