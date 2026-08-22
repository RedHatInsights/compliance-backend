class AddUniqueIndexOnPolicyAndOsMinorToTailorings < ActiveRecord::Migration[8.1]
  def change
    add_index :tailorings, %i[policy_id os_minor_version], unique: true
  end
end
