class DeletePolicies < ActiveRecord::Migration[5.2]
  def change
    drop_table :policies
  end
end
