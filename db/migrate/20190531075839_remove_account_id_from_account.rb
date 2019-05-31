class RemoveAccountIdFromAccount < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :account_id
  end
end
