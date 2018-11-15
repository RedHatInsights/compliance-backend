class AddAccountIdToHosts < ActiveRecord::Migration[5.2]
  def change
    add_column :hosts, :account_id, :uuid
    add_index :hosts, :account_id
  end
end
