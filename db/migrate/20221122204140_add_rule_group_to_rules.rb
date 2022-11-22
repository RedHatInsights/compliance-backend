class AddRuleGroupToRules < ActiveRecord::Migration[7.0]
  def change
    add_column :rules, :rule_group_id, :uuid, index: true
    add_foreign_key :rules, :rule_groups
  end
end
