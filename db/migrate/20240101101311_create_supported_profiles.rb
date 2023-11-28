class CreateSupportedProfiles < ActiveRecord::Migration[7.0]
  def change
    create_view :supported_profiles
  end
end
