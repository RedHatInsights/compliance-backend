# frozen_string_literal: true

class AddTestResultIdResultIndexToRuleResults < ActiveRecord::Migration[8.0]
  def change
    add_index :rule_results, [:test_result_id, :result],
              name: 'index_rule_results_on_test_result_id_and_result'
  end
end
