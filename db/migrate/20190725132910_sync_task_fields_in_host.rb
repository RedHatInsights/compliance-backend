class SyncTaskFieldsInHost < ActiveRecord::Migration[5.2]
  def change
    add_column :hosts, :last_seen_in_inventory, :datetime, default: Date.today
    add_index :hosts, :last_seen_in_inventory
    add_column :hosts, :disabled, :boolean, default: false
    add_index :hosts, :disabled
  end
end
