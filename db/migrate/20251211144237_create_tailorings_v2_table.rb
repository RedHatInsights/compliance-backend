class CreateTailoringsV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :tailorings_v2, id: :uuid do |t|
      t.uuid :policy_id
      t.uuid :profile_id
      t.jsonb :value_overrides
      t.integer :os_minor_version

      t.timestamps
    end

    add_index :tailorings_v2, [:os_minor_version], name: 'index_tailorings_v2_on_os_minor_version'
    add_index :tailorings_v2, [:profile_id], name: 'index_tailorings_v2_on_profile_id'
    add_index :tailorings_v2, [:policy_id], name: 'index_tailorings_v2_on_policy_id'
  end
end
