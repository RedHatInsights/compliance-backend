class RemoveAccountNumberFromAccounts < ActiveRecord::Migration[7.0]
  def change
    remove_index :accounts, :account_number
    remove_column :accounts, :account_number, :string
  end
end
