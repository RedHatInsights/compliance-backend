# frozen_string_literal: true

# Creates table to store hosts whic hwe cansend later to the inventory
class CreateHosts < ActiveRecord::Migration[5.2]
  def change
    create_table :hosts, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
    add_index :hosts, :name
  end
end
