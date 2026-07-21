class RenameV2Tables < ActiveRecord::Migration[8.1]
  def change
    # Triggers and functions on v2_test_results must be dropped before the view itself
    drop_trigger :v2_test_results_insert, on: :v2_test_results, revert_to_version: 1
    drop_trigger :v2_test_results_delete, on: :v2_test_results, revert_to_version: 1
    drop_function :v2_test_results_insert, revert_to_version: 2
    drop_function :v2_test_results_delete, revert_to_version: 2

    # Views reference V2-named tables and must be dropped before the renames
    drop_view :v2_test_results,   revert_to_version: 5
    drop_view :report_systems,    revert_to_version: 2
    drop_view :supported_profiles, revert_to_version: 4

    # Rename V2 tables to their canonical names (removing _v2 suffix / v2_ prefix)
    rename_table :security_guides_v2,          :security_guides
    rename_table :value_definitions_v2,        :value_definitions
    rename_table :canonical_profiles_v2,       :profiles
    rename_table :rules_v2,                    :rules
    rename_table :rule_groups_v2,              :rule_groups
    rename_table :profile_rules_v2,            :profile_rules
    rename_table :policies_v2,                 :policies
    rename_table :policy_systems_v2,           :policy_systems
    rename_table :tailorings_v2,               :tailorings
    rename_table :tailoring_rules_v2,          :tailoring_rules
    rename_table :historical_test_results_v2,  :historical_test_results
    rename_table :rule_results_v2,             :rule_results

    # Rename indexes that still carry the old _v2 table name in their identifier
    rename_index :historical_test_results,
                 :index_historical_test_results_v2_on_system_tailoring_end_time,
                 :index_historical_test_results_on_system_tailoring_end_time
    rename_index :historical_test_results,
                 :index_historical_test_results_v2_for_latest_lookup,
                 :index_historical_test_results_for_latest_lookup
    rename_index :rules,
                 :index_rules_v2_on_identifier_labels,
                 :index_rules_on_identifier_labels

    # Recreate functions with updated references to the renamed tables
    create_function :test_results_insert
    create_function :test_results_delete

    # Recreate views with SQL that references the renamed tables
    create_view :test_results
    create_view :report_systems,     version: 3
    create_view :supported_profiles, version: 5

    # Recreate triggers on the renamed view
    create_trigger :test_results_insert, on: :test_results
    create_trigger :test_results_delete, on: :test_results
  end
end
