class CreateV1PolicyHostsFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_policy_hosts_insert
    create_function :v1_policy_hosts_delete
    create_trigger :v1_policy_hosts_insert, on: :v1_policy_hosts
    create_trigger :v1_policy_hosts_delete, on: :v1_policy_hosts
  end
end
