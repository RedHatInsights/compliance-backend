class MakeTailoringsWritable < ActiveRecord::Migration[7.0]
  def change
    create_function :tailorings_insert
    create_trigger :tailorings_insert, on: :tailorings
  end
end
