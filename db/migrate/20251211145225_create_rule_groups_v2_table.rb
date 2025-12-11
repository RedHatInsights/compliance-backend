class CreateRuleGroupsV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :rule_groups_v2, id: :uuid do |t|
      t.string :ref_id
      t.string :title
      t.text :description
      t.text :rationale
      t.string :ancestry
      t.uuid :security_guide_id
      t.uuid :rule_id
      t.integer :precedence

      t.timestamps
    end

    add_index :rule_groups_v2, [:ancestry], name: 'index_rule_groups_v2_on_ancestry'
    add_index :rule_groups_v2, [:security_guide_id], name: 'index_rule_groups_v2_on_security_guide_id'
    add_index :rule_groups_v2, [:precedence], name: 'index_rule_groups_v2_on_precedence'
    add_index :rule_groups_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_rule_groups_v2_on_ref_id_and_security_guide_id'
    add_index :rule_groups_v2, [:rule_id], unique: true, name: 'index_rule_groups_v2_on_rule_id'
  end
end
