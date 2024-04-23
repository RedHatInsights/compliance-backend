class CreateTriggerV2RulesInsert < ActiveRecord::Migration[7.1]
  def change
    create_trigger :v2_rules_insert, on: :v2_rules
  end
end
