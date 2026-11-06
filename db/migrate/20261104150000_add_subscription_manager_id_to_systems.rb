class AddSubscriptionManagerIdToSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :systems, :subscription_manager_id, :uuid
  end
end
