# frozen_string_literal: true

class AddSeverityIndexToRulesV2 < ActiveRecord::Migration[8.0]
  def change
    add_index :rules_v2, :severity,
              name: 'index_rules_v2_on_severity'
  end
end
