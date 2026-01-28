class CreateV1RuleGroupsView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_rule_groups
  end
end
