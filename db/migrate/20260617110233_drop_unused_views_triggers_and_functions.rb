class DropUnusedViewsTriggersAndFunctions < ActiveRecord::Migration[8.1]
  def change
    drop_trigger :tailorings_insert,              on: :tailorings,              revert_to_version: 1
    drop_trigger :v2_policies_insert,             on: :v2_policies,             revert_to_version: 1
    drop_trigger :v2_policies_update,             on: :v2_policies,             revert_to_version: 1
    drop_trigger :v2_policies_delete,             on: :v2_policies,             revert_to_version: 1
    drop_trigger :historical_test_results_delete, on: :historical_test_results, revert_to_version: 1

    drop_trigger :v1_benchmarks_insert,                on: :v1_benchmarks,                revert_to_version: 1
    drop_trigger :v1_benchmarks_update,                on: :v1_benchmarks,                revert_to_version: 1
    drop_trigger :v1_rules_insert,                     on: :v1_rules,                     revert_to_version: 1
    drop_trigger :v1_rules_update,                     on: :v1_rules,                     revert_to_version: 1
    drop_trigger :v1_value_definitions_insert,         on: :v1_value_definitions,         revert_to_version: 1
    drop_trigger :v1_rule_groups_insert,               on: :v1_rule_groups,               revert_to_version: 1
    drop_trigger :v1_rule_groups_update,               on: :v1_rule_groups,               revert_to_version: 1
    drop_trigger :v1_rule_group_relationships_insert,  on: :v1_rule_group_relationships,  revert_to_version: 1
    drop_trigger :v1_rule_group_relationships_update,  on: :v1_rule_group_relationships,  revert_to_version: 1
    drop_trigger :v1_profile_rules_insert,             on: :v1_profile_rules,             revert_to_version: 1
    drop_trigger :v1_profile_rules_update,             on: :v1_profile_rules,             revert_to_version: 1
    drop_trigger :v1_profile_rules_delete,             on: :v1_profile_rules,             revert_to_version: 1
    drop_trigger :v1_policies_insert,                  on: :v1_policies,                  revert_to_version: 1
    drop_trigger :v1_policies_update,                  on: :v1_policies,                  revert_to_version: 1
    drop_trigger :v1_policies_delete,                  on: :v1_policies,                  revert_to_version: 1
    drop_trigger :v1_test_results_insert,              on: :v1_test_results,              revert_to_version: 1
    drop_trigger :v1_test_results_delete,              on: :v1_test_results,              revert_to_version: 1
    drop_trigger :v1_policy_hosts_insert,              on: :v1_policy_hosts,              revert_to_version: 1
    drop_trigger :v1_policy_hosts_delete,              on: :v1_policy_hosts,              revert_to_version: 1
    drop_trigger :v1_profiles_insert,                  on: :v1_profiles,                  revert_to_version: 1
    drop_trigger :v1_profiles_update,                  on: :v1_profiles,                  revert_to_version: 1
    drop_trigger :v1_profiles_delete,                  on: :v1_profiles,                  revert_to_version: 1
    drop_trigger :v1_rule_results_insert,              on: :v1_rule_results,              revert_to_version: 1
    drop_trigger :v1_rule_results_delete,              on: :v1_rule_results,              revert_to_version: 1

    drop_view :canonical_profiles,      revert_to_version: 3
    drop_view :historical_test_results, revert_to_version: 1
    drop_view :policy_systems,          revert_to_version: 1
    drop_view :tailoring_rules,         revert_to_version: 1
    drop_view :tailorings,              revert_to_version: 3
    drop_view :v2_policies,             revert_to_version: 3

    drop_view :v1_benchmarks,               revert_to_version: 1
    drop_view :v1_rules,                    revert_to_version: 1
    drop_view :v1_value_definitions,        revert_to_version: 1
    drop_view :v1_rule_groups,              revert_to_version: 1
    drop_view :v1_rule_group_relationships, revert_to_version: 1
    drop_view :v1_profile_rules,            revert_to_version: 3
    drop_view :v1_policies,                 revert_to_version: 1
    drop_view :v1_test_results,             revert_to_version: 1
    drop_view :v1_policy_hosts,             revert_to_version: 1
    drop_view :v1_profiles,                 revert_to_version: 2
    drop_view :v1_rule_results,             revert_to_version: 1
    drop_view :v1_rule_references_containers, revert_to_version: 1

    drop_function :tailorings_insert,  revert_to_version: 7
    drop_function :v2_policies_insert, revert_to_version: 1
    drop_function :v2_policies_update, revert_to_version: 1
    drop_function :v2_policies_delete, revert_to_version: 1

    drop_function :v1_benchmarks_insert,               revert_to_version: 1
    drop_function :v1_benchmarks_update,               revert_to_version: 1
    drop_function :v1_rules_insert,                    revert_to_version: 1
    drop_function :v1_rules_update,                    revert_to_version: 1
    drop_function :v1_value_definitions_insert,        revert_to_version: 1
    drop_function :v1_rule_groups_insert,              revert_to_version: 1
    drop_function :v1_rule_groups_update,              revert_to_version: 1
    drop_function :v1_rule_group_relationships_insert, revert_to_version: 1
    drop_function :v1_rule_group_relationships_update, revert_to_version: 1
    drop_function :v1_profile_rules_insert,            revert_to_version: 3
    drop_function :v1_profile_rules_update,            revert_to_version: 3
    drop_function :v1_profile_rules_delete,            revert_to_version: 3
    drop_function :v1_policies_insert,                 revert_to_version: 1
    drop_function :v1_policies_update,                 revert_to_version: 1
    drop_function :v1_policies_delete,                 revert_to_version: 1
    drop_function :v1_test_results_insert,             revert_to_version: 1
    drop_function :v1_test_results_delete,             revert_to_version: 1
    drop_function :v1_policy_hosts_insert,             revert_to_version: 1
    drop_function :v1_policy_hosts_delete,             revert_to_version: 1
    drop_function :v1_profiles_insert,                 revert_to_version: 2
    drop_function :v1_profiles_update,                 revert_to_version: 2
    drop_function :v1_profiles_delete,                 revert_to_version: 2
    drop_function :v1_rule_results_insert,             revert_to_version: 1
    drop_function :v1_rule_results_delete,             revert_to_version: 1
  end
end
