class CreateRuleGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :rule_groups, id: :uuid do |t|
      t.string :ref_id
      t.string :title
      t.text :description
      t.text :rationale
      t.string :ancestry
      t.index :ancestry
      t.references :benchmark, type: :uuid, null: false, foreign_key: true
      t.references :rule, type: :uuid, foreign_key: true, index: {unique: true}
      t.index [:ref_id, :benchmark_id], unique: true
    end

    create_table :rule_group_rules, id: :uuid do |t|
      t.references :rule_group, type: :uuid, foreign_key: true
      t.references :rule, type: :uuid, foreign_key: true
      t.index [:rule_group_id, :rule_id], unique: true
    end

    create_table :rule_group_relationships, id: :uuid do |t|
      t.references :left, type: :uuid, polymorphic: true
      t.references :right, type: :uuid, polymorphic: true
      t.string :relationship
      t.index [:left_id, :right_id, :right_type, :left_type, :relationship],
               name: 'index_rule_group_relationships_unique',
               unique: true
    end

    create_table :profile_rule_groups, id: :uuid do |t|
      t.references :profile, type: :uuid, index: true, null: false
      t.references :rule_group, type: :uuid, index: true, null: false
      t.index [:profile_id, :rule_group_id], unique: true

      t.timestamps
    end
  end
end
