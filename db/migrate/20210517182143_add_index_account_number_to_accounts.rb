class AddIndexAccountNumberToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_index :accounts, :account_number
  end
end
