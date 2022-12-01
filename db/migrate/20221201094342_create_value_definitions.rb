# frozen_string_literal: true

# Data model for storing value definitions
class CreateValueDefinitions < ActiveRecord::Migration[7.0]
  def change
    create_table :value_definitions, id: :uuid do |t|
      t.string :ref_id
      t.string :title
      t.text :description
      t.string :value_type
      t.string :default_value
      t.numeric :lower_bound, default: nil
      t.numeric :upper_bound, default: nil
      t.references :benchmark, type: :uuid, null: false, foreign_key: true
      t.index [:ref_id, :benchmark_id], unique: true
    end

    add_column :rules, :value_checks, :uuid, array: true, default: []
    add_column :profiles, :value_overrides, :jsonb, default: {}
  end
end
