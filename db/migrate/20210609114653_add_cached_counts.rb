class AddCachedCounts < ActiveRecord::Migration[5.2]
  def up
    add_column :policies, :total_host_count, :integer, null: false, default: 0
    add_column :policies, :test_result_host_count, :integer, null: false, default: 0
    add_column :policies, :compliant_host_count, :integer, null: false, default: 0
    add_column :policies, :unsupported_host_count, :integer, null: false, default: 0

    Policy.find_each(&:update_counters!)
  end

  def down
    remove_column :policies, :total_host_count
    remove_column :policies, :test_result_host_count
    remove_column :policies, :compliant_host_count
    remove_column :policies, :unsupported_host_count
  end
end
