class DeclareTailoringsTrigger < ActiveRecord::Migration[7.0]
  def change
    create_trigger :tailorings_insert, on: :tailorings
  end
end
