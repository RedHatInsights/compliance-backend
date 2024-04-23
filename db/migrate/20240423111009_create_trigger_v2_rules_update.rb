class CreateTriggerV2RulesUpdate < ActiveRecord::Migration[7.1]
  def change
    create_trigger :v2_rules_update, on: :v2_rules
  end
end
