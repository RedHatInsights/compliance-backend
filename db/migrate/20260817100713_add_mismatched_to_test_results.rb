class AddMismatchedToTestResults < ActiveRecord::Migration[8.1]
  def change
    add_column :historical_test_results, :mismatched, :boolean, default: false, null: false

    drop_trigger :test_results_insert, on: :test_results, revert_to_version: 1
    drop_trigger :test_results_delete, on: :test_results, revert_to_version: 1
    update_function :test_results_insert, version: 3, revert_to_version: 2
    update_view :test_results, version: 2, revert_to_version: 1
    create_trigger :test_results_insert, on: :test_results
    create_trigger :test_results_delete, on: :test_results
  end
end
