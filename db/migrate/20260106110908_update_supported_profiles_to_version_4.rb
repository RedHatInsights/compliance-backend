class UpdateSupportedProfilesToVersion4 < ActiveRecord::Migration[8.0]
  def change
    update_view :supported_profiles, version: 4, revert_to_version: 3
  end
end
