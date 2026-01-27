class CreateV1RuleGroupRelationshipsView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_rule_group_relationships
  end
end
