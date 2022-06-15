class AccountOrgIdNotNull < ActiveRecord::Migration[7.0]
  def up
    change_column :accounts, :org_id, :string, null: false
    change_column :accounts, :account_number, :string, null: true
    add_index :accounts, :org_id, unique: true
  end

  def down
    change_column :accounts, :org_id, :string, null: true
    change_column :accounts, :account_number, :string, null: false
    remove_index :accounts, :org_id, unique: true
  end
end
