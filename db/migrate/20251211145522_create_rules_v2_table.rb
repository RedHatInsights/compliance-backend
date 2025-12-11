class CreateRulesV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :rules_v2, id: :uuid do |t|
      t.string :ref_id
      t.string :title
      t.string :severity
      t.text :description
      t.text :rationale
      t.boolean :remediation_available, default: false, null: false
      t.uuid :security_guide_id, null: false
      t.boolean :upstream, default: true, null: false
      t.integer :precedence
      t.uuid :rule_group_id, null: false
      t.jsonb :value_checks, default: [], array: true
      t.jsonb :identifier
      t.jsonb :references

      t.timestamps
    end

    add_index :rules_v2, [:precedence], name: 'index_rules_v2_on_precedence'
    add_index :rules_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_rules_v2_on_ref_id_and_security_guide_id'
    add_index :rules_v2, [:ref_id], name: 'index_rules_v2_on_ref_id'
    add_index :rules_v2, [:upstream], name: 'index_rules_v2_on_upstream'
    add_index :rules_v2, "((identifier -> 'label'::text))", using: :gin, name: 'index_rules_v2_on_identifier_labels'
    add_index :rules_v2, [:references], name: 'index_rules_v2_on_references', using: :gin, opclass: :jsonb_path_ops
  end
end
