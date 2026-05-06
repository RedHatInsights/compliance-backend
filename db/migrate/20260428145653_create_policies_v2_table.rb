class CreatePoliciesV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :policies_v2, id: :uuid do |t|
      t.string :title, null: true
      t.string :description
      t.float :compliance_threshold, default: 100.0, null: true
      t.string :business_objective
      t.references :profile, type: :uuid, index: false, null: true
      t.references :account, type: :uuid, index: false, null: true

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO policies_v2 (id, title, description, compliance_threshold, business_objective,
        profile_id, account_id, created_at, updated_at)
      SELECT id, title, description, compliance_threshold, business_objective,
        profile_id, account_id, NOW(), NOW()
      FROM v2_policies;
    SQL

    change_column_null :policies_v2, :title, false
    change_column_null :policies_v2, :compliance_threshold, false
    change_column_null :policies_v2, :profile_id, false
    change_column_null :policies_v2, :account_id, false
    change_column_null :policies_v2, :created_at, false
    change_column_null :policies_v2, :updated_at, false

    add_index :policies_v2, [:account_id], name: 'index_policies_v2_on_account_id'
    add_index :policies_v2, [:profile_id], name: 'index_policies_v2_on_profile_id'
  end

  def down
    drop_table :policies_v2
  end
end
