class AddExternalToProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :external, :boolean, default: false, null: false
    add_index :profiles, :external
  end
end
