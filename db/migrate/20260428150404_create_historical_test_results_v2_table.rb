class CreateHistoricalTestResultsV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :historical_test_results_v2, id: :uuid do |t|
      t.datetime :start_time, precision: nil
      t.datetime :end_time, precision: nil
      t.decimal :score
      t.boolean :supported, default: true, null: true
      t.integer :failed_rule_count, default: 0, null: true
      t.references :tailoring, type: :uuid, index: false, null: true
      t.uuid :report_id, null: true
      t.uuid :system_id, null: true

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO historical_test_results_v2 (id, tailoring_id, report_id, system_id, start_time, end_time,
        score, supported, failed_rule_count, created_at, updated_at)
      SELECT id, tailoring_id, report_id, system_id, start_time, end_time,
        score, supported, failed_rule_count, created_at, updated_at
      FROM historical_test_results;
    SQL

    change_column_null :historical_test_results_v2, :tailoring_id, false
    change_column_null :historical_test_results_v2, :report_id, false
    change_column_null :historical_test_results_v2, :system_id, false
    change_column_null :historical_test_results_v2, :supported, false
    change_column_null :historical_test_results_v2, :failed_rule_count, false
    change_column_null :historical_test_results_v2, :created_at, false
    change_column_null :historical_test_results_v2, :updated_at, false

    add_index :historical_test_results_v2, [:tailoring_id], name: 'index_historical_test_results_v2_on_tailoring_id'
    add_index :historical_test_results_v2, [:system_id], name: 'index_historical_test_results_v2_on_system_id'
    add_index :historical_test_results_v2, [:system_id, :tailoring_id, :end_time], unique: true, name: 'index_historical_test_results_v2_on_system_tailoring_end_time'
    add_index :historical_test_results_v2, [:supported], name: 'index_historical_test_results_v2_on_supported'
  end

  def down
    drop_table :historical_test_results_v2
  end
end
