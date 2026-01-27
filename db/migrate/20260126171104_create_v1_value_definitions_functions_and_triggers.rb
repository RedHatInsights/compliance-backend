class CreateV1ValueDefinitionsFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_value_definitions_insert
    create_trigger :v1_value_definitions_insert, on: :v1_value_definitions
  end
end
