class UpdateV2TestResultsToVersion5 < ActiveRecord::Migration[8.0]
  def change
    drop_trigger :v2_test_results_delete, on: :v2_test_results, revert_to_version: 1
    drop_trigger :v2_test_results_insert, on: :v2_test_results, revert_to_version: 1

    update_view :v2_test_results, version: 5, revert_to_version: 4

    create_trigger :v2_test_results_insert, on: :v2_test_results
    create_trigger :v2_test_results_delete, on: :v2_test_results
  end
end
