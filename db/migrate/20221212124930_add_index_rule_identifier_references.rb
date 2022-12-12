class AddIndexRuleIdentifierReferences < ActiveRecord::Migration[7.0]
  def change
    add_index :rules, "(identifier -> 'label')", using: 'gin', name: 'index_rules_on_identifier_labels'
    add_index :rule_references_containers, :rule_references, using: 'gin', opclass: :jsonb_path_ops
  end
end
