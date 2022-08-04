class DeduplicateAccounts < ActiveRecord::Migration[5.2]
  def up
    remove_index :accounts, :account_number
    add_index :accounts, :account_number, unique: true
  end

  def down
    remove_index :accounts, :account_number
    add_index :accounts, :account_number
  end
end
