class UpdateV2TestResultsFunctionsToVersion2 < ActiveRecord::Migration[8.0]
  def change
    drop_trigger :v2_test_results_delete, on: :v2_test_results, revert_to_version: 1
    drop_trigger :v2_test_results_insert, on: :v2_test_results, revert_to_version: 1

    drop_trigger :historical_test_results_delete, on: :historical_test_results, revert_to_version: 1

    update_function :v2_test_results_insert, version: 2, revert_to_version: 1
    update_function :v2_test_results_delete, version: 2, revert_to_version: 1

    create_trigger :v2_test_results_insert, on: :v2_test_results
    create_trigger :v2_test_results_delete, on: :v2_test_results
  end
end
