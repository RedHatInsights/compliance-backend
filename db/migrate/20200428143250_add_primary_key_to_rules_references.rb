class AddPrimaryKeyToRulesReferences < ActiveRecord::Migration[5.2]
  def change
    add_column :rule_references_rules, :id, :primary_key
  end
end
