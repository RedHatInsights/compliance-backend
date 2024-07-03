class UpdateFunctionV2RulesUpdateToVersion2 < ActiveRecord::Migration[7.1]
  def change
    drop_trigger :v2_rules_update, on: :v2_rules
    update_function :v2_rules_update, version: 2, revert_to_version: 1
    create_trigger :v2_rules_update, on: :v2_rules
  end
end
