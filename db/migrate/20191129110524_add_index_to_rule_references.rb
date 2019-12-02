class AddIndexToRuleReferences < ActiveRecord::Migration[5.2]
  def change
    add_index :rule_references_rules, :rule_id
  end
end
