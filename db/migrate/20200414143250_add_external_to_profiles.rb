class AddExternalToProfiles < ActiveRecord::Migration[5.2]
  def up
    add_column :profiles, :external, :boolean, default: false, null: false
    add_index :profiles, :external
    ExternalProfileUpdater.run!(DateTime.parse('2020-04-13T10:44:00+00:00'))
  end

  def down
    remove_index :profiles, :external
    remove_column :profiles, :external
  end
end
