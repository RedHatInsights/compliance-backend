class RemoveThresholdBusinessObjectiveFromProfiles < ActiveRecord::Migration[5.2]
  def change
    remove_index :profiles, :business_objective_id
    remove_column :profiles, :business_objective_id, :uuid

    remove_column :profiles, :compliance_threshold, :float, default: 100
  end
end
