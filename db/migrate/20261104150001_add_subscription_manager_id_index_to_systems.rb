class AddSubscriptionManagerIdIndexToSystems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :systems, :subscription_manager_id,
              where: 'deleted_at IS NULL',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
