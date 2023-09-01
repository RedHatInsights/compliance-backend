class CreateV2ValueDefinitions < ActiveRecord::Migration[7.0]
  def change
    create_view :v2_value_definitions
  end
end
