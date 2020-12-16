class AddPolicyIdForeignKeyOnProfiles < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :profiles, :policies
  end
end
