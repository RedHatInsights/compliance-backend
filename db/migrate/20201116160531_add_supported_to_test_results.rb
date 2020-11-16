class AddSupportedToTestResults < ActiveRecord::Migration[5.2]
  def change
    add_column :test_results, :supported, :boolean, default: true
    add_index :test_results, :supported
  end
end
