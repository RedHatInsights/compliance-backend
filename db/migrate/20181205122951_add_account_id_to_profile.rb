class AddAccountIdToProfile < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :account_id, :uuid
    add_index :profiles, :account_id
  end
end
