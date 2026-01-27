class CreateV1RuleGroupRelationshipsFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_rule_group_relationships_insert
    create_function :v1_rule_group_relationships_update
    create_trigger :v1_rule_group_relationships_insert, on: :v1_rule_group_relationships
    create_trigger :v1_rule_group_relationships_update, on: :v1_rule_group_relationships
  end
end
