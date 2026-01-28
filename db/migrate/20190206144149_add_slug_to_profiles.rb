class AddSlugToProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :slug, :string
    add_index :profiles, :slug, unique: true

    # Removed so we're able to change the table name of Profiles
    # Profile.all.map(&:save)
  end
end
