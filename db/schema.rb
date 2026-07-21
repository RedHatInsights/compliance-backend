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

ActiveRecord::Schema[8.1].define(version: 2026_07_21_150715) do
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

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.integer "lock_type", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["created_at"], name: "index_good_jobs_on_created_at"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_on_discarded", order: { finished_at: :desc }, where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["id"], name: "index_good_jobs_on_unfinished_or_errored", where: "((finished_at IS NULL) OR (error IS NOT NULL))"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", order: { priority: "ASC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_for_candidate_dequeue_unlocked", order: { priority: "ASC NULLS LAST" }, where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_on_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", order: { priority: "ASC NULLS LAST" }, where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at", "id"], name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["queue_name"], name: "index_good_jobs_on_queue_name"
    t.index ["scheduled_at", "queue_name"], name: "index_good_jobs_on_scheduled_at_and_queue_name"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
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
    t.string "org_id", limit: 36, null: false
    t.datetime "stale_timestamp", null: false
    t.jsonb "system_profile", default: {}, null: false
    t.jsonb "tags", default: {}, null: false
    t.datetime "updated", null: false
    t.index ["deleted_at"], name: "index_systems_on_deleted_at_partial", where: "(deleted_at IS NOT NULL)"
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

  create_trigger :v2_test_results_insert, sql_definition: <<-SQL
      CREATE TRIGGER v2_test_results_insert INSTEAD OF INSERT ON public.v2_test_results FOR EACH ROW EXECUTE FUNCTION v2_test_results_insert()
  SQL

  create_trigger :v2_test_results_delete, sql_definition: <<-SQL
      CREATE TRIGGER v2_test_results_delete INSTEAD OF DELETE ON public.v2_test_results FOR EACH ROW EXECUTE FUNCTION v2_test_results_delete()
  SQL
end
