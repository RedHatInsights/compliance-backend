class RemoveEmptyBenchmarks < ActiveRecord::Migration[5.2]
  def up
    ::Xccdf::Benchmark.transaction do
      empty_benchmarks = ::Xccdf::Benchmark.where.not(
        id: Profile.select(:benchmark_id).distinct
      )
      empty_benchmarks.each do |empty_benchmark|
        ::RuleIdentifier.where(
          rule_id: empty_benchmark.rules.select(:id)
        ).delete_all
        empty_rule_references_rules = ::RuleReferencesRule.where(
          rule_id: empty_benchmark.rules.select(:id)
        )
        ::RuleReference.where(
          id: empty_rule_references_rules.select(:rule_reference_id)
        ).delete_all
        empty_rule_references_rules.delete_all
        empty_benchmark.rules.delete_all
      end
      empty_benchmarks.destroy_all
    end
  end

  def down
  end
end
