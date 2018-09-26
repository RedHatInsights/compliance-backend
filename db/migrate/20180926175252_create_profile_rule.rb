# frozen_string_literal: true

# Creates a join table for linking profiles and rules
class CreateProfileRule < ActiveRecord::Migration[5.2]
  def change
    create_table :profile_rules, id: :uuid do |t|
      t.references :profile, type: :uuid, index: true, null: false
      t.references :rule, type: :uuid, index: true, null: false

      t.timestamps null: true
    end
    add_index(:profile_rules, %i[profile_id rule_id], unique: true)
  end
end
