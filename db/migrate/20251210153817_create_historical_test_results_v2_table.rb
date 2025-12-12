class CreateHistoricalTestResultsV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :historical_test_results_v2, id: :uuid do |t|
      t.uuid :tailoring_id
      t.uuid :report_id
      t.uuid :system_id
      t.datetime :start_time
      t.datetime :end_time
      t.float :score
      t.boolean :supported, default: true
      t.integer :failed_rule_count, default: 0, null: false

      t.timestamps
    end

    add_index :historical_test_results_v2, [:system_id, :tailoring_id, :end_time], unique: true, name: 'index_hst_test_results_v2_on_system_and_tailoring_and_end_time'
    add_index :historical_test_results_v2, [:system_id], name: 'index_historical_test_results_v2_on_system_id'
    add_index :historical_test_results_v2, [:tailoring_id], name: 'index_historical_test_results_v2_on_tailoring_id'
    add_index :historical_test_results_v2, [:supported], name: 'index_historical_test_results_v2_on_supported'

    add_index :historical_test_results_v2, [:report_id], name: 'index_historical_test_results_v2_on_report_id'
  end
end
