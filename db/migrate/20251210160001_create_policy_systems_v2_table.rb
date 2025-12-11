class CreatePolicySystemsV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :policy_systems_v2, id: :uuid do |t|
      t.uuid :policy_id
      t.uuid :system_id

      t.timestamps
    end

    add_index :policy_systems_v2, [:policy_id, :system_id], unique: true, name: 'index_policy_systems_v2_on_policy_id_and_system_id'
    add_index :policy_systems_v2, [:policy_id], name: 'index_policy_systems_v2_on_policy_id'
    add_index :policy_systems_v2, [:system_id], name: 'index_policy_systems_v2_on_system_id'
  end
end
