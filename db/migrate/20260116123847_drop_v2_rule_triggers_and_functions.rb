class DropV2RuleTriggersAndFunctions < ActiveRecord::Migration[8.0]
  def change
    drop_trigger :v2_rules_insert, on: :v2_rules, revert_to_version: 1
    drop_trigger :v2_rules_update, on: :v2_rules, revert_to_version: 1
    drop_trigger :v2_rules_delete, on: :v2_rules, revert_to_version: 1
    drop_function :v2_rules_insert, revert_to_version: 2
    drop_function :v2_rules_update, revert_to_version: 2
    drop_function :v2_rules_delete, revert_to_version: 1
  end
end
