class UpdateFunctionV1ProfileRulesInsertToVersion2 < ActiveRecord::Migration[8.0]
  def change
    drop_trigger :v1_profile_rules_insert, on: :v1_profile_rules, revert_to_version: 1
    update_function :v1_profile_rules_insert, version: 2, revert_to_version: 1
    create_trigger :v1_profile_rules_insert, on: :v1_profile_rules
  end
end
