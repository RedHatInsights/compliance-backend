class UpdateV2RulesToVersion2 < ActiveRecord::Migration[7.1]
  def change
  
    update_view :v2_rules, version: 2, revert_to_version: 1
  end
end
