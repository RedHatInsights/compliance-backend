class AddUniqueIndexToRuleResults < ActiveRecord::Migration[5.2]
  def up
    add_index(:rule_results, %i[host_id rule_id test_result_id], unique: true)
  end

  def down
    remove_index(:rule_results, %i[host_id rule_id test_result_id])
  end
end
