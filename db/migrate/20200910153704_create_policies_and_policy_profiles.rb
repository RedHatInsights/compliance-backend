class CreatePoliciesAndPolicyProfiles < ActiveRecord::Migration[5.2]
  def change
    create_table :policies, id: :uuid do |t|
      t.references :business_objective, foreign_key: true, type: :uuid
      t.float :compliance_threshold, default: 100
      t.string :name
      t.string :description
      t.references :account, foreign_key: true, type: :uuid
    end

    create_table :policy_hosts, id: :uuid do |t|
      t.references :policy, foreign_key: true, type: :uuid, null: false
      t.references :host, foreign_key: true, type: :uuid, null: false

      t.timestamps null: true
    end
    add_index(:policy_hosts, %i[policy_id host_id], unique: true)

    add_reference :profiles, :policy, type: :uuid
  end
end
