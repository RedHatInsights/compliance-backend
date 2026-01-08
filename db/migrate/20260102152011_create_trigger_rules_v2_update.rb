class CreateTriggerRulesV2Update < ActiveRecord::Migration[8.0]
  def change
    create_trigger :rules_v2_update, on: :rules_v2
  end
end
