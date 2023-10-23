class CreateTailorings < ActiveRecord::Migration[7.0]
  def change
    create_view :tailorings
  end
end
