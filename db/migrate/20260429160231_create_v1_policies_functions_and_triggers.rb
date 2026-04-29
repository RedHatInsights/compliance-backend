class CreateV1PoliciesFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_policies_insert
    create_function :v1_policies_update
    create_function :v1_policies_delete
    create_trigger :v1_policies_insert, on: :v1_policies
    create_trigger :v1_policies_update, on: :v1_policies
    create_trigger :v1_policies_delete, on: :v1_policies
  end
end
