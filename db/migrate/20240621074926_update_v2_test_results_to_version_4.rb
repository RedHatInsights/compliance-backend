class UpdateV2TestResultsToVersion4 < ActiveRecord::Migration[7.1]
  def change
    drop_trigger :v2_test_results_insert, on: :v2_test_results
    drop_trigger :v2_test_results_delete, on: :v2_test_results
    update_view :v2_test_results, version: 4, revert_to_version: 3
    create_trigger :v2_test_results_insert, on: :v2_test_results
    create_trigger :v2_test_results_delete, on: :v2_test_results
  end
end
