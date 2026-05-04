class DropFriendlyIdSlugs < ActiveRecord::Migration[8.1]
  def change
    drop_table(:friendly_id_slugs) {}
  end
end
