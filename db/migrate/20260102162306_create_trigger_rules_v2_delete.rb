class CreateTriggerRulesV2Delete < ActiveRecord::Migration[8.0]
  def change
    create_trigger :rules_v2_delete, on: :rules_v2
  end
end
