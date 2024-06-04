class UpdateV2TestResultsToVersion3 < ActiveRecord::Migration[7.1]
  def change
    update_view :v2_test_results, version: 3, revert_to_version: 2
  end
end
