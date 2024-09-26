class UpdateSupportedProfilesToVersion3 < ActiveRecord::Migration[7.1]
  def change

    update_view :supported_profiles, version: 3, revert_to_version: 2
  end
end
