class UpdateSecurityGuidesToVersion2 < ActiveRecord::Migration[7.0]
  def change
  
    update_view :security_guides, version: 2, revert_to_version: 1
  end
end
