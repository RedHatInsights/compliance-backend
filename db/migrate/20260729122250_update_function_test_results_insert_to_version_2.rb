class UpdateFunctionTestResultsInsertToVersion2 < ActiveRecord::Migration[8.1]
  def change
    drop_trigger :test_results_insert, on: :test_results, revert_to_version: 1

    update_function :test_results_insert, version: 2, revert_to_version: 1

    create_trigger :test_results_insert, on: :test_results
  end
end
