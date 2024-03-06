class UpdateV2PoliciesToVersion3 < ActiveRecord::Migration[7.0]
  def change
    drop_view :reports, revert_to_version: 1
    update_view :v2_policies, version: 3, revert_to_version: 2
    create_view :reports, version: 2

    create_trigger :v2_policies_insert, on: :v2_policies
    create_trigger :v2_policies_delete, on: :v2_policies
    create_trigger :v2_policies_update, on: :v2_policies
  end
end
