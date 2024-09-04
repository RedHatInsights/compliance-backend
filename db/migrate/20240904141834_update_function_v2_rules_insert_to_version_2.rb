class UpdateFunctionV2RulesInsertToVersion2 < ActiveRecord::Migration[7.1]
  def change
    drop_trigger :v2_rules_insert, on: :v2_rules
    update_function :v2_rules_insert, version: 2, revert_to_version: 1
    create_trigger :v2_rules_insert, on: :v2_rules
  end
end
