class CreateRulesV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :rules_v2, id: :uuid do |t|
      t.string :ref_id
      t.string :title
      t.string :severity
      t.text :description
      t.text :rationale
      t.boolean :remediation_available, default: false, null: true
      t.references :security_guide, type: :uuid, index: false, null: true
      t.boolean :upstream, default: false, null: true
      t.integer :precedence
      t.references :rule_group, type: :uuid, index: false
      t.uuid :value_checks, default: [], array: true
      t.jsonb :identifier
      t.jsonb :references

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO rules_v2 (id, ref_id, title, severity, description, rationale, remediation_available, security_guide_id, upstream, precedence, rule_group_id, value_checks, identifier, "references", created_at, updated_at)
      SELECT id, ref_id, title, severity, description, rationale, remediation_available, security_guide_id, upstream, precedence, rule_group_id, value_checks, identifier, "references", created_at, updated_at
      FROM v2_rules;
    SQL

    change_column_null :rules_v2, :remediation_available, false
    change_column_null :rules_v2, :security_guide_id, false
    change_column_null :rules_v2, :upstream, false
    change_column_null :rules_v2, :created_at, false
    change_column_null :rules_v2, :updated_at, false

    add_index :rules_v2, "((identifier -> 'label'::text))", using: :gin, name: 'index_rules_v2_on_identifier_labels'
    add_index :rules_v2, [:precedence], name: 'index_rules_v2_on_precedence'
    add_index :rules_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_rules_v2_on_ref_id_and_security_guide_id'
    add_index :rules_v2, [:ref_id], name: 'index_rules_v2_on_ref_id'
    add_index :rules_v2, [:upstream], name: 'index_rules_v2_on_upstream'
    add_index :rules_v2, [:references], opclass: :jsonb_path_ops, using: :gin, name: 'index_rules_v2_on_references'
  end

  def down
    drop_table :rules_v2
  end
end
