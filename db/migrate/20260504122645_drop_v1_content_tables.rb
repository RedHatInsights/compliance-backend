class DropV1ContentTables < ActiveRecord::Migration[8.1]
  def change
    drop_table(:rule_group_relationships) {}

    drop_trigger :v2_rules_insert, on: :v2_rules, revert_to_version: 1
    drop_trigger :v2_rules_update, on: :v2_rules, revert_to_version: 1
    drop_trigger :v2_rules_delete, on: :v2_rules, revert_to_version: 1
    drop_function :v2_rules_insert, revert_to_version: 2
    drop_function :v2_rules_update, revert_to_version: 2
    drop_function :v2_rules_delete, revert_to_version: 1
    drop_view :v2_rules, revert_to_version: 2
    drop_table(:rule_references_containers) {}
    drop_table(:rules) {}

    drop_view :v2_rule_groups, revert_to_version: 1
    drop_table(:rule_groups) {}

    drop_view :v2_value_definitions, revert_to_version: 1
    drop_table(:value_definitions) {}

    drop_view :security_guides, revert_to_version: 2
    drop_table(:benchmarks) {}
  end
end
