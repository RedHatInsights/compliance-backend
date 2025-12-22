class CreateProfileRulesV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :profile_rules_v2, id: :uuid do |t|
      t.references :profile, type: :uuid, null: false
      t.references :rule, type: :uuid, null: false

      t.timestamps precision: nil
    end

    add_index :profile_rules_v2, [:profile_id, :rule_id], unique: true, name: 'index_profile_rules_v2_on_profile_id_and_rule_id'

    execute <<-SQL
      INSERT INTO profile_rules_v2 (id, profile_id, rule_id, created_at, updated_at)
      SELECT pr.id, pr.profile_id, pr.rule_id, pr.created_at, pr.updated_at
      FROM profile_rules AS pr JOIN profiles AS p ON pr.profile_id = p.id WHERE p.parent_profile_id IS NULL;
    SQL
  end

  def down
    drop_table :profile_rules_v2
  end
end
