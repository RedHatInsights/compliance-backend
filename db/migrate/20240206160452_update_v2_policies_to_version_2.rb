class UpdateV2PoliciesToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_view :v2_policies, version: 2, revert_to_version: 1

    create_trigger :v2_policies_insert, on: :v2_policies
    create_trigger :v2_policies_delete, on: :v2_policies
    create_trigger :v2_policies_update, on: :v2_policies
  end
end
