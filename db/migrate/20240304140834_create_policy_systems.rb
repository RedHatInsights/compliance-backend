class CreatePolicySystems < ActiveRecord::Migration[7.0]
  def change
    create_view :policy_systems
  end
end
