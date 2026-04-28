class CreateTailoringRulesV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :tailoring_rules_v2, id: :uuid do |t|
      t.references :tailoring, type: :uuid, index: false, null: true
      t.references :rule, type: :uuid, index: false, null: true

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO tailoring_rules_v2 (id, tailoring_id, rule_id, created_at, updated_at)
      SELECT pr.id, pr.profile_id, pr.rule_id, pr.created_at, pr.updated_at
      FROM profile_rules pr
      JOIN profiles p ON pr.profile_id = p.id
      WHERE p.parent_profile_id IS NOT NULL;
    SQL

    change_column_null :tailoring_rules_v2, :tailoring_id, false
    change_column_null :tailoring_rules_v2, :rule_id, false
    change_column_null :tailoring_rules_v2, :created_at, false
    change_column_null :tailoring_rules_v2, :updated_at, false

    add_index :tailoring_rules_v2, [:tailoring_id], name: 'index_tailoring_rules_v2_on_tailoring_id'
    add_index :tailoring_rules_v2, [:rule_id], name: 'index_tailoring_rules_v2_on_rule_id'
    add_index :tailoring_rules_v2, [:tailoring_id, :rule_id], unique: true, name: 'index_tailoring_rules_v2_on_tailoring_id_and_rule_id'
  end

  def down
    drop_table :tailoring_rules_v2
  end
end
