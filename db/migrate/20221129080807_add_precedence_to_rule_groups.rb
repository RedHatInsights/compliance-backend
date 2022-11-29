class AddPrecedenceToRuleGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :rule_groups, :precedence, :integer
    add_index :rule_groups, :precedence
    add_index :rules, :precedence
  end
end
