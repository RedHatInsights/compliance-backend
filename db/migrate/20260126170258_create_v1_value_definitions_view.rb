class CreateV1ValueDefinitionsView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_value_definitions
  end
end
