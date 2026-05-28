class CreateTailoringsV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :tailorings_v2, id: :uuid do |t|
      t.integer :os_minor_version, null: true
      t.jsonb :value_overrides, default: {}
      t.references :policy, type: :uuid, index: false, null: true
      t.references :profile, type: :uuid, index: false, null: true

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO tailorings_v2 (id, policy_id, profile_id, value_overrides, os_minor_version, created_at, updated_at)
      SELECT id, policy_id, profile_id, value_overrides, os_minor_version, created_at, updated_at
      FROM tailorings;
    SQL

    change_column_null :tailorings_v2, :policy_id, false
    change_column_null :tailorings_v2, :profile_id, false
    change_column_null :tailorings_v2, :created_at, false
    change_column_null :tailorings_v2, :updated_at, false

    add_index :tailorings_v2, [:policy_id], name: 'index_tailorings_v2_on_policy_id'
    add_index :tailorings_v2, [:profile_id], name: 'index_tailorings_v2_on_profile_id'
  end

  def down
    drop_table :tailorings_v2
  end
end
