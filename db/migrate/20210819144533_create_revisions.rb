# frozen_string_literal: true

# Create revisions table, meant to store config file revisions
class CreateRevisions < ActiveRecord::Migration[5.2]
  def change
    create_table :revisions, id: :uuid do |t|
      t.string :name, null: false
      t.string :revision, null: false

      t.timestamps
    end

    add_index :revisions, :name, unique: true
  end
end
