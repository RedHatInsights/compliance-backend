# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_15_174517) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "account_number"
    t.boolean "internal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "benchmarks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "version", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ref_id", "version"], name: "index_benchmarks_on_ref_id_and_version", unique: true
  end

  create_table "business_objectives", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_business_objectives_on_title"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "hosts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "account_id"
    t.integer "os_major_version"
    t.integer "os_minor_version"
    t.index ["account_id"], name: "index_hosts_on_account_id"
    t.index ["name"], name: "index_hosts_on_name"
    t.index ["os_major_version"], name: "index_hosts_on_os_major_version"
    t.index ["os_minor_version"], name: "index_hosts_on_os_minor_version"
  end

  create_table "policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "business_objective_id"
    t.float "compliance_threshold", default: 100.0
    t.string "name"
    t.string "description"
    t.uuid "account_id"
    t.index ["account_id"], name: "index_policies_on_account_id"
    t.index ["business_objective_id"], name: "index_policies_on_business_objective_id"
  end

  create_table "policy_hosts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "policy_id", null: false
    t.uuid "host_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["host_id"], name: "index_policy_hosts_on_host_id"
    t.index ["policy_id", "host_id"], name: "index_policy_hosts_on_policy_id_and_host_id", unique: true
    t.index ["policy_id"], name: "index_policy_hosts_on_policy_id"
  end

  create_table "profile_hosts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "host_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["host_id"], name: "index_profile_hosts_on_host_id"
    t.index ["profile_id", "host_id"], name: "index_profile_hosts_on_profile_id_and_host_id", unique: true
    t.index ["profile_id"], name: "index_profile_hosts_on_profile_id"
  end

  create_table "profile_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "rule_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["profile_id", "rule_id"], name: "index_profile_rules_on_profile_id_and_rule_id", unique: true
    t.index ["profile_id"], name: "index_profile_rules_on_profile_id"
    t.index ["rule_id"], name: "index_profile_rules_on_rule_id"
  end

  create_table "profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "ref_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.uuid "account_id"
    t.float "compliance_threshold", default: 100.0
    t.uuid "business_objective_id"
    t.uuid "benchmark_id", null: false
    t.uuid "parent_profile_id"
    t.boolean "external", default: false, null: false
    t.uuid "policy_id"
    t.index ["account_id"], name: "index_profiles_on_account_id"
    t.index ["business_objective_id"], name: "index_profiles_on_business_objective_id"
    t.index ["external"], name: "index_profiles_on_external"
    t.index ["name"], name: "index_profiles_on_name"
    t.index ["parent_profile_id"], name: "index_profiles_on_parent_profile_id"
    t.index ["policy_id"], name: "index_profiles_on_policy_id"
    t.index ["ref_id", "account_id", "benchmark_id", "external"], name: "uniqueness", unique: true
  end

  create_table "rule_identifiers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "label"
    t.string "system"
    t.uuid "rule_id"
    t.index ["label", "system", "rule_id"], name: "index_rule_identifiers_on_label_and_system_and_rule_id", unique: true
    t.index ["rule_id"], name: "index_rule_identifiers_on_rule_id"
  end

  create_table "rule_references", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "href"
    t.string "label"
    t.index ["href", "label"], name: "index_rule_references_on_href_and_label", unique: true
  end

  create_table "rule_references_rules", id: false, force: :cascade do |t|
    t.uuid "rule_id", null: false
    t.uuid "rule_reference_id", null: false
    t.index ["rule_id", "rule_reference_id"], name: "index_rule_references_rules_on_rule_id_and_rule_reference_id", unique: true
    t.index ["rule_id"], name: "index_rule_references_rules_on_rule_id"
    t.index ["rule_reference_id"], name: "index_rule_references_rules_on_rule_reference_id"
  end

  create_table "rule_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "host_id"
    t.uuid "rule_id"
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.boolean "remediation_available", default: false, null: false
    t.uuid "benchmark_id", null: false
    t.index ["ref_id", "benchmark_id"], name: "index_rules_on_ref_id_and_benchmark_id", unique: true
    t.index ["ref_id"], name: "index_rules_on_ref_id"
    t.index ["slug"], name: "index_rules_on_slug", unique: true
  end

  create_table "test_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal "score"
    t.uuid "profile_id"
    t.uuid "host_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id", "profile_id", "end_time"], name: "index_test_results_on_host_id_and_profile_id_and_end_time", unique: true
    t.index ["host_id"], name: "index_test_results_on_host_id"
    t.index ["profile_id"], name: "index_test_results_on_profile_id"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  add_foreign_key "policies", "accounts"
  add_foreign_key "policies", "business_objectives"
  add_foreign_key "policy_hosts", "hosts"
  add_foreign_key "policy_hosts", "policies"
  add_foreign_key "profiles", "profiles", column: "parent_profile_id"
end
