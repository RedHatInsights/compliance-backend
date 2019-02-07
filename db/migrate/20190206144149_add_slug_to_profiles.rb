class AddSlugToProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :slug, :string
    add_index :profiles, :slug, unique: true

    Profile.all.map(&:save)
  end
end
