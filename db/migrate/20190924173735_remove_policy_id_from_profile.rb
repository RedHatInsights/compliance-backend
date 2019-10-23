class RemovePolicyIdFromProfile < ActiveRecord::Migration[5.2]
  def change
    remove_column :profiles, :policy_id, :uuid
  end
end
