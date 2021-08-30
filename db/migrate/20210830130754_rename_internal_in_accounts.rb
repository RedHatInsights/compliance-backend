class RenameInternalInAccounts < ActiveRecord::Migration[5.2]
  def change
    rename_column :accounts, :internal, :is_internal
  end
end
