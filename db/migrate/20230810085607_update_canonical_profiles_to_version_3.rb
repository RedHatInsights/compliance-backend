class UpdateCanonicalProfilesToVersion3 < ActiveRecord::Migration[7.0]
  def change
  
    update_view :canonical_profiles, version: 3, revert_to_version: 2
  end
end
