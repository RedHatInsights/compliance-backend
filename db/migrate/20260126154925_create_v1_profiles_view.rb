class CreateV1ProfilesView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_profiles
  end
end
