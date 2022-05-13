class OrgIdToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :org_id, :string, index: { unique: true }
  end
end
