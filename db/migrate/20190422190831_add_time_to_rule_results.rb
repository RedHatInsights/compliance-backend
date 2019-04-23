class AddTimeToRuleResults < ActiveRecord::Migration[5.2]
  def change
    add_column :rule_results, :start_time, :datetime
    add_column :rule_results, :end_time, :datetime
  end
end
