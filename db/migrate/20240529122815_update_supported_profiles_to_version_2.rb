class UpdateSupportedProfilesToVersion2 < ActiveRecord::Migration[7.1]
  def change
  
    update_view :supported_profiles, version: 2, revert_to_version: 1
  end
end
