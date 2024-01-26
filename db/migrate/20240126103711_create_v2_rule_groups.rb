class CreateV2RuleGroups < ActiveRecord::Migration[7.0]
  def change
    create_view :v2_rule_groups
  end
end
