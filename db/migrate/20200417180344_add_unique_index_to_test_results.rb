class AddUniqueIndexToTestResults < ActiveRecord::Migration[5.2]
  def up
    add_index(:test_results, %i[host_id profile_id end_time], unique: true)
  end

  def down
    remove_index(:test_results, %i[host_id profile_id end_time])
  end
end
