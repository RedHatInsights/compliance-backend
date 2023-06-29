class RemoveIsInternalFromAccounts < ActiveRecord::Migration[7.0]
  def change
    remove_column :accounts, :is_internal, :boolean
  end
end
