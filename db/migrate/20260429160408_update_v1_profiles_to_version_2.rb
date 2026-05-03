class UpdateV1ProfilesToVersion2 < ActiveRecord::Migration[8.0]
  def change
    drop_trigger :v1_profiles_delete, on: :v1_profiles, revert_to_version: 1
    drop_trigger :v1_profiles_insert, on: :v1_profiles, revert_to_version: 1
    drop_trigger :v1_profiles_update, on: :v1_profiles, revert_to_version: 1

    update_view :v1_profiles, version: 2, revert_to_version: 1

    update_function :v1_profiles_insert, version: 2, revert_to_version: 1
    update_function :v1_profiles_update, version: 2, revert_to_version: 1
    update_function :v1_profiles_delete, version: 2, revert_to_version: 1

    create_trigger :v1_profiles_insert, on: :v1_profiles
    create_trigger :v1_profiles_update, on: :v1_profiles
    create_trigger :v1_profiles_delete, on: :v1_profiles
  end
end
