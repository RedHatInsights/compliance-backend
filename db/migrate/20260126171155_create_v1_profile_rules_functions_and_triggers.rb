class CreateV1ProfileRulesFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_profile_rules_insert
    create_function :v1_profile_rules_update
    create_function :v1_profile_rules_delete
    create_trigger :v1_profile_rules_insert, on: :v1_profile_rules
    create_trigger :v1_profile_rules_update, on: :v1_profile_rules
    create_trigger :v1_profile_rules_delete, on: :v1_profile_rules
  end
end
