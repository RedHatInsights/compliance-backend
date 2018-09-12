class CreateProfiles < ActiveRecord::Migration[5.2]
  def change
    create_table :profiles do |t|
      t.string :name
      t.references :policy, type: :uuid, index: true

      t.timestamps
    end
    add_index :profiles, :name, unique: true
  end
end
