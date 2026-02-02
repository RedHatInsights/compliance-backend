class CreateProfileRulesV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :profile_rules_v2, id: :uuid do |t|
      t.references :profile, type: :uuid, index: false, null: true
      t.references :rule, type: :uuid, index: false, null: true

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO profile_rules_v2 (id, profile_id, rule_id, created_at, updated_at)
      SELECT pr.id, pr.profile_id, pr.rule_id, pr.created_at, pr.updated_at
      FROM profile_rules AS pr JOIN profiles AS p ON pr.profile_id = p.id WHERE p.parent_profile_id IS NULL;
    SQL

    change_column_null :profile_rules_v2, :profile_id, false
    change_column_null :profile_rules_v2, :rule_id, false
    change_column_null :profile_rules_v2, :created_at, false
    change_column_null :profile_rules_v2, :updated_at, false

    add_index :profile_rules_v2, [:profile_id], name: 'index_profile_rules_v2_on_profile_id'
    add_index :profile_rules_v2, [:rule_id], name: 'index_profile_rules_v2_on_rule_id'
    add_index :profile_rules_v2, [:profile_id, :rule_id], unique: true, name: 'index_profile_rules_v2_on_profile_id_and_rule_id'
  end

  def down
    drop_table :profile_rules_v2
  end
end
