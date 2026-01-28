class CreateV1ProfilesFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_profiles_insert
    create_function :v1_profiles_update
    create_function :v1_profiles_delete
    create_trigger :v1_profiles_insert, on: :v1_profiles
    create_trigger :v1_profiles_update, on: :v1_profiles
    create_trigger :v1_profiles_delete, on: :v1_profiles
  end
end
