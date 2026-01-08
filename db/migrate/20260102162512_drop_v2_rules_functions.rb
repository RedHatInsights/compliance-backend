class DropV2RulesFunctions < ActiveRecord::Migration[8.0]
  def change
    drop_function :v2_rules_insert, revert_to_version: 2
    drop_function :v2_rules_update, revert_to_version: 2
    drop_function :v2_rules_delete, revert_to_version: 1
  end
end
