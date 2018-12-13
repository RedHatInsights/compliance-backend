class RemoveUniqueIndexForProfiles < ActiveRecord::Migration[5.2]
  def change
    remove_index :profiles, :name
    add_index :profiles, :name
  end
end
