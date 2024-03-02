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

ActiveRecord::Schema[7.0].define(version: 2024_03_02_162345) do
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

  create_table "test_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.decimal "score"
    t.uuid "profile_id"
    t.uuid "host_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "supported", default: true
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

  add_foreign_key "policies", "accounts"
  add_foreign_key "policies", "business_objectives"
  add_foreign_key "policies", "profiles"
  add_foreign_key "policy_hosts", "policies"
  add_foreign_key "profiles", "policies"
  add_foreign_key "profiles", "profiles", column: "parent_profile_id"
  add_foreign_key "rule_groups", "benchmarks"
  add_foreign_key "rule_groups", "rules"
  add_foreign_key "rule_references_containers", "rules"
  add_foreign_key "rules", "rule_groups"
  add_foreign_key "value_definitions", "benchmarks"

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
  create_view "v2_rules", sql_definition: <<-SQL
      SELECT rules.id,
      rules.ref_id,
      rules.supported,
      rules.title,
      rules.severity,
      rules.description,
      rules.rationale,
      rules.created_at,
      rules.updated_at,
      rules.slug,
      rules.remediation_available,
      rules.benchmark_id AS security_guide_id,
      rules.upstream,
      rules.precedence,
      rules.rule_group_id,
      rules.value_checks,
      rules.identifier
     FROM rules;
  SQL
  create_view "tailorings", sql_definition: <<-SQL
      SELECT profiles.id,
      profiles.policy_id,
      profiles.parent_profile_id AS profile_id,
      profiles.value_overrides,
      profiles.os_minor_version,
      profiles.created_at,
      profiles.updated_at
     FROM profiles
    WHERE (profiles.parent_profile_id IS NOT NULL);
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
  create_view "supported_profiles", sql_definition: <<-SQL
      SELECT (array_agg(canonical_profiles.id ORDER BY (string_to_array((security_guides.version)::text, '.'::text))::integer[] DESC))[1] AS id,
      (array_agg(canonical_profiles.title ORDER BY (string_to_array((security_guides.version)::text, '.'::text))::integer[] DESC))[1] AS title,
      canonical_profiles.ref_id,
      (array_agg(security_guides.version ORDER BY (string_to_array((security_guides.version)::text, '.'::text))::integer[] DESC))[1] AS security_guide_version,
      security_guides.os_major_version,
      array_agg(DISTINCT profile_os_minor_versions.os_minor_version ORDER BY profile_os_minor_versions.os_minor_version DESC) AS os_minor_versions
     FROM ((canonical_profiles
       JOIN security_guides ON ((security_guides.id = canonical_profiles.security_guide_id)))
       JOIN profile_os_minor_versions ON ((profile_os_minor_versions.profile_id = canonical_profiles.id)))
    GROUP BY canonical_profiles.ref_id, security_guides.os_major_version;
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
  create_view "v2_policies", sql_definition: <<-SQL
      SELECT policies.id,
      policies.name AS title,
      policies.description,
      policies.compliance_threshold,
      business_objectives.title AS business_objective,
      COALESCE(sq.system_count, (0)::bigint) AS system_count,
      policies.profile_id,
      policies.account_id
     FROM ((policies
       LEFT JOIN business_objectives ON ((business_objectives.id = policies.business_objective_id)))
       LEFT JOIN ( SELECT count(policy_hosts.host_id) AS system_count,
              policy_hosts.policy_id
             FROM policy_hosts
            GROUP BY policy_hosts.policy_id) sq ON ((sq.policy_id = policies.id)));
  SQL
  create_view "reports", sql_definition: <<-SQL
      SELECT v2_policies.id,
      v2_policies.title,
      v2_policies.description,
      v2_policies.compliance_threshold,
      v2_policies.business_objective,
      v2_policies.system_count,
      v2_policies.profile_id,
      v2_policies.account_id
     FROM ((v2_policies
       JOIN tailorings ON ((tailorings.policy_id = v2_policies.id)))
       JOIN test_results ON ((test_results.profile_id = tailorings.id)))
    GROUP BY v2_policies.id, v2_policies.title, v2_policies.description, v2_policies.compliance_threshold, v2_policies.business_objective, v2_policies.system_count, v2_policies.profile_id, v2_policies.account_id;
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
  create_function :tailorings_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.tailorings_insert()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      DECLARE result_id uuid;
      BEGIN

      INSERT INTO "profiles" (
        "policy_id",
        "account_id",
        "parent_profile_id",
        "benchmark_id",
        "os_minor_version",
        "value_overrides",
        "created_at",
        "updated_at"
      ) SELECT
        NEW."policy_id",
        "policies"."account_id",
        NEW."profile_id",
        "canonical_profiles"."security_guide_id",
        NEW."os_minor_version",
        NEW."value_overrides",
        NEW."created_at",
        NEW."updated_at"
      FROM "policies"
      INNER JOIN "canonical_profiles" ON "canonical_profiles"."id" = "policies"."profile_id"
      WHERE "policies"."id" = NEW."policy_id" RETURNING "id" INTO "result_id";

      NEW."id" := "result_id";
      RETURN NEW;

      END
      $function$
  SQL


  create_trigger :tailorings_insert, sql_definition: <<-SQL
      CREATE TRIGGER tailorings_insert INSTEAD OF INSERT ON public.tailorings FOR EACH ROW EXECUTE FUNCTION tailorings_insert()
  SQL
  create_trigger :v2_policies_update, sql_definition: <<-SQL
      CREATE TRIGGER v2_policies_update INSTEAD OF UPDATE ON public.v2_policies FOR EACH ROW EXECUTE FUNCTION v2_policies_update()
  SQL
  create_trigger :v2_policies_delete, sql_definition: <<-SQL
      CREATE TRIGGER v2_policies_delete INSTEAD OF DELETE ON public.v2_policies FOR EACH ROW EXECUTE FUNCTION v2_policies_delete()
  SQL
  create_trigger :v2_policies_insert, sql_definition: <<-SQL
      CREATE TRIGGER v2_policies_insert INSTEAD OF INSERT ON public.v2_policies FOR EACH ROW EXECUTE FUNCTION v2_policies_insert()
  SQL
end
