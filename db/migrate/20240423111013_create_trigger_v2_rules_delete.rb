class CreateTriggerV2RulesDelete < ActiveRecord::Migration[7.1]
  def change
    create_trigger :v2_rules_delete, on: :v2_rules
  end
end
