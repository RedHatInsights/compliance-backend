class AddExternalToProfiles < ActiveRecord::Migration[5.2]
  def up
    add_column :profiles, :external, :boolean, default: false, null: false
    add_index :profiles, :external
  end

  def down
    remove_index :profiles, :external
    remove_column :profiles, :external
  end
end
