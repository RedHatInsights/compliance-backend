class CreateRuleGroupRelationshipsV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :rule_group_relationships_v2, id: :uuid do |t|
      t.references :left, type: :uuid, polymorphic: true, index: false, null: true
      t.references :right, type: :uuid, polymorphic: true, index: false, null: true
      t.string :relationship

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO rule_group_relationships_v2 (id, left_id, left_type, right_id, right_type, relationship, created_at, updated_at)
      SELECT id, left_id, left_type, right_id, right_type, relationship, NOW(), NOW()
      FROM rule_group_relationships;
    SQL

    change_column_null :rule_group_relationships_v2, :left_id, false
    change_column_null :rule_group_relationships_v2, :right_id, false
    change_column_null :rule_group_relationships_v2, :relationship, false
    change_column_null :rule_group_relationships_v2, :created_at, false
    change_column_null :rule_group_relationships_v2, :updated_at, false

    add_index :rule_group_relationships_v2, [:left_type, :left_id], name: 'index_rule_group_relationships_v2_on_left'
    add_index :rule_group_relationships_v2, [:right_type, :right_id], name: 'index_rule_group_relationships_v2_on_right'
    add_index :rule_group_relationships_v2, [:left_id, :right_id, :right_type, :left_type, :relationship], unique: true, name: 'unique_index_rule_group_relationships_v2'
  end

  def down
    drop_table :rule_group_relationships_v2
  end
end
