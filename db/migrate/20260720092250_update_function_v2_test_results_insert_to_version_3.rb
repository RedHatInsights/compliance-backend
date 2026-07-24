class UpdateFunctionV2TestResultsInsertToVersion3 < ActiveRecord::Migration[8.1]
  def change
    drop_trigger :v2_test_results_insert, on: :v2_test_results, revert_to_version: 1

    update_function :v2_test_results_insert, version: 3, revert_to_version: 2

    create_trigger :v2_test_results_insert, on: :v2_test_results
  end
end
