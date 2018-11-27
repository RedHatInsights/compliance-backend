class AddDescriptionToProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :description, :string
  end
end
