class CreateV1RuleGroupsFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_rule_groups_insert
    create_function :v1_rule_groups_update
    create_trigger :v1_rule_groups_insert, on: :v1_rule_groups
    create_trigger :v1_rule_groups_update, on: :v1_rule_groups
  end
end
