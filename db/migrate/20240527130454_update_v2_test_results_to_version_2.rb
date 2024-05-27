class UpdateV2TestResultsToVersion2 < ActiveRecord::Migration[7.1]
  def change
    update_view :v2_test_results, version: 2, revert_to_version: 1
  end
end
