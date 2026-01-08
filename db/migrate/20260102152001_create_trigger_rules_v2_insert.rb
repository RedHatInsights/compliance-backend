class CreateTriggerRulesV2Insert < ActiveRecord::Migration[8.0]
  def change
    create_trigger :rules_v2_insert, on: :rules_v2
  end
end
