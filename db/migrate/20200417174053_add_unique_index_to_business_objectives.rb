class AddUniqueIndexToBusinessObjectives < ActiveRecord::Migration[5.2]
  def change
    add_index :business_objectives, :title
  end
end
