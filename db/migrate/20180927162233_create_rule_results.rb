# frozen_string_literal: true

# Creates table to store a history of whether a host passed or not a
# certain rule, timestamped
class CreateRuleResults < ActiveRecord::Migration[5.2]
  def change
    create_table :rule_results, id: :uuid do |t|
      t.references :host
      t.references :rule
      t.string :result

      t.timestamps
    end
  end
end
