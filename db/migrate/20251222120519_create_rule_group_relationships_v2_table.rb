class CreateRuleGroupRelationshipsV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :rule_group_relationships_v2, id: :uuid do |t|
      t.references :left, type: :uuid, polymorphic: true
      t.references :right, type: :uuid, polymorphic: true
      t.string :relationship

      t.timestamps precision: nil
    end

    add_index :rule_group_relationships_v2, [:left_id, :right_id, :right_type, :left_type, :relationship], unique: true, name: 'uniq_index_rule_group_relationships_v2'

    execute <<-SQL
      INSERT INTO rule_group_relationships_v2 (id, left_id, left_type, right_id, right_type, relationship, created_at, updated_at)
      SELECT id, left_id, left_type, right_id, right_type, relationship, NOW(), NOW()
      FROM rule_group_relationships;
    SQL
  end

  def down
    drop_table :rule_group_relationships_v2
  end
end
