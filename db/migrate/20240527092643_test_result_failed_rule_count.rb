class TestResultFailedRuleCount < ActiveRecord::Migration[7.1]
  def up
    add_column :test_results, :failed_rule_count, :integer, default: 0, null: false

    sq = TestResult.joins(:rule_results).where(rule_results: { result: %w[fail error unknown fixed] })
                                        .group('test_results.id').select('test_results.id', 'COUNT(rule_results.id) as cnt')


    ActiveRecord::Base.connection.execute(
      "UPDATE test_results SET failed_rule_count = sq.cnt FROM (#{sq.to_sql}) AS sq WHERE sq.id = test_results.id"
    )
  end

  def down
    remove_column :test_results, :failed_rule_count
  end
end
