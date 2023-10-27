class MakeV2PoliciesWritable < ActiveRecord::Migration[7.0]
  def change
    create_function :v2_policies_insert
    create_trigger :v2_policies_insert, on: :v2_policies
    create_function :v2_policies_delete
    create_trigger :v2_policies_delete, on: :v2_policies
    create_function :v2_policies_update
    create_trigger :v2_policies_update, on: :v2_policies
  end
end
