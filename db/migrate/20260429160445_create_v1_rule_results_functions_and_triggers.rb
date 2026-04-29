class CreateV1RuleResultsFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_rule_results_insert
    create_function :v1_rule_results_delete
    create_trigger :v1_rule_results_insert, on: :v1_rule_results
    create_trigger :v1_rule_results_delete, on: :v1_rule_results
  end
end
