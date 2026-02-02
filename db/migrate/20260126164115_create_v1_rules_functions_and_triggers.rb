class CreateV1RulesFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_rules_insert
    create_function :v1_rules_update
    create_trigger :v1_rules_insert, on: :v1_rules
    create_trigger :v1_rules_update, on: :v1_rules
  end
end
