class AddComplianceThresholdToProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :compliance_threshold, :float, default: 100
  end
end
