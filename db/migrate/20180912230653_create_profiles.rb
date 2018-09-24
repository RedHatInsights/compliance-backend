# frozen_string_literal: true

# Create profiles table, meant to store profile attributes from OpenSCAP
class CreateProfiles < ActiveRecord::Migration[5.2]
  def change
    create_table :profiles, id: :uuid do |t|
      t.string :name
      t.string :ref_id
      t.references :policy, type: :uuid, index: true

      t.timestamps
    end
    add_index :profiles, :name, unique: true
  end
end
