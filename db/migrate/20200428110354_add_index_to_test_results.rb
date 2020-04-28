class AddIndexToTestResults < ActiveRecord::Migration[5.2]
  def change
    add_index :test_results, [:profile_id, :host_id, :end_time]
  end
end
