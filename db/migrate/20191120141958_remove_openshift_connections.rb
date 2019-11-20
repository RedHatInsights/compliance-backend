class RemoveOpenshiftConnections < ActiveRecord::Migration[5.2]
  def change
    drop_table :openshift_connections
  end
end
