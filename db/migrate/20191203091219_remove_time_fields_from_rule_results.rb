class RemoveTimeFieldsFromRuleResults < ActiveRecord::Migration[5.2]
  def up
    remove_column :rule_results, :start_time
    remove_column :rule_results, :end_time
  end

  def down
    add_column :rule_results, :start_time, :datetime
    add_column :rule_results, :end_time, :datetime
    TestResult.find_each do |test_result|
      rule_result_ids = test_result.rule_results.pluck(:id)
      RuleResult.where(id: rule_result_ids).update_all(
        start_time: test_result.start_time, end_time: test_result.end_time
      )
    end
  end
end
