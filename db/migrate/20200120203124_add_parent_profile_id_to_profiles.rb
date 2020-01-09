class AddParentProfileIdToProfiles < ActiveRecord::Migration[5.2]
  def change
    add_reference :profiles, :parent_profile, type: :uuid, foreign_key: { to_table: :profiles }
  end
end
