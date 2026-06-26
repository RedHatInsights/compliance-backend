# frozen_string_literal: true

class DropV1Tables < ActiveRecord::Migration[8.1]
  def change
    drop_trigger :v2_policies_insert, on: :v2_policies, revert_to_version: 1
    drop_trigger :v2_policies_update, on: :v2_policies, revert_to_version: 1
    drop_trigger :v2_policies_delete, on: :v2_policies, revert_to_version: 1

    drop_trigger :tailorings_insert, on: :tailorings, revert_to_version: 1

    drop_trigger :historical_test_results_delete, on: :historical_test_results, revert_to_version: 1

    drop_trigger :v1_policies_insert, on: :v1_policies, revert_to_version: 1
    drop_trigger :v1_policies_update, on: :v1_policies, revert_to_version: 1
    drop_trigger :v1_policies_delete, on: :v1_policies, revert_to_version: 1

    drop_view :v2_policies, revert_to_version: 3
    drop_view :canonical_profiles, revert_to_version: 3
    drop_view :tailorings, revert_to_version: 3
    drop_view :historical_test_results, revert_to_version: 1
    drop_view :policy_systems, revert_to_version: 1
    drop_view :tailoring_rules, revert_to_version: 1
    drop_view :v1_policies, revert_to_version: 1

    drop_function :v2_policies_insert, revert_to_version: 1
    drop_function :v2_policies_update, revert_to_version: 1
    drop_function :v2_policies_delete, revert_to_version: 1
    drop_function :tailorings_insert, revert_to_version: 7
    drop_function :v1_policies_insert, revert_to_version: 1
    drop_function :v1_policies_update, revert_to_version: 1
    drop_function :v1_policies_delete, revert_to_version: 1

    drop_table(:rule_results) {}
    drop_table(:profile_rules) {}
    drop_table(:policy_hosts) {}
    drop_table(:test_results) {}
    drop_table(:profiles) {}
    drop_table(:business_objectives) {}
    drop_table(:policies) {}
  end
end
