class RemoveSlugFromProfiles < ActiveRecord::Migration[5.2]
  def change
    remove_column :profiles, :slug
  end
end
