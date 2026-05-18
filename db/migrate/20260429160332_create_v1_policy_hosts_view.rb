class CreateV1PolicyHostsView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_policy_hosts
  end
end
