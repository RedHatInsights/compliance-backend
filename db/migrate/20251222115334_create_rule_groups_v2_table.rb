class CreateRuleGroupsV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :rule_groups_v2, id: :uuid do |t|
      t.string :ref_id
      t.string :title
      t.text :description
      t.text :rationale
      t.string :ancestry
      t.references :security_guide, type: :uuid, null: false
      t.references :rule, type: :uuid, null: true, index: {unique: true}
      t.integer :precedence

      t.timestamps precision: nil
    end

    add_index :rule_groups_v2, [:ancestry], name: 'index_rule_groups_v2_on_ancestry'
    add_index :rule_groups_v2, [:precedence], name: 'index_rule_groups_v2_on_precedence'
    add_index :rule_groups_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_rule_groups_v2_on_ref_id_and_security_guide_id'

    execute <<-SQL
      INSERT INTO rule_groups_v2 (id, ref_id, title, description, rationale, ancestry, security_guide_id, rule_id, precedence, created_at, updated_at)
      SELECT id, ref_id, title, description, rationale, ancestry, security_guide_id, rule_id, precedence, NOW(), NOW()
      FROM v2_rule_groups;
    SQL
  end

  def down
    drop_table :rule_groups_v2
  end
end
