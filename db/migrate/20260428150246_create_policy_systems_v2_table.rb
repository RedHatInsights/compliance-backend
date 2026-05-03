class CreatePolicySystemsV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :policy_systems_v2, id: :uuid do |t|
      t.references :policy, type: :uuid, index: false, null: true
      t.uuid :system_id, null: true

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO policy_systems_v2 (id, policy_id, system_id, created_at, updated_at)
      SELECT id, policy_id, host_id, created_at, updated_at
      FROM policy_hosts;
    SQL

    change_column_null :policy_systems_v2, :policy_id, false
    change_column_null :policy_systems_v2, :system_id, false
    change_column_null :policy_systems_v2, :created_at, false
    change_column_null :policy_systems_v2, :updated_at, false

    add_index :policy_systems_v2, [:system_id], name: 'index_policy_systems_v2_on_system_id'
    add_index :policy_systems_v2, [:policy_id], name: 'index_policy_systems_v2_on_policy_id'
    add_index :policy_systems_v2, [:policy_id, :system_id], unique: true, name: 'index_policy_systems_v2_on_policy_id_and_system_id'
  end

  def down
    drop_table :policy_systems_v2
  end
end
