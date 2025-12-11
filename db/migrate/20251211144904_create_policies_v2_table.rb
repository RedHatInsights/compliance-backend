class CreatePoliciesV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :policies_v2, id: :uuid do |t|
      t.string :title
      t.string :description
      t.integer :compliance_threshold
      t.string :business_objective
      t.integer :total_system_count
      t.uuid :profile_id
      t.uuid :account_id

      t.timestamps
    end

    add_index :policies_v2, [:account_id], name: 'index_policies_v2_on_account_id'
    add_index :policies_v2, [:business_objective], name: 'index_policies_v2_on_business_objective'
    add_index :policies_v2, [:profile_id], name: 'index_policies_v2_on_profile_id'
  end
end
