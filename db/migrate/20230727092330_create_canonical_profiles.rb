class CreateCanonicalProfiles < ActiveRecord::Migration[7.0]
  def change
    create_view :canonical_profiles
  end
end
