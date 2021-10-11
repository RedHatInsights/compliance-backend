# frozen_string_literal: true

# Service for removing upstream rule bindings without test resuls
class UpstreamRuleBindingsRemover
  def self.run!
    ProfileRule.left_outer_joins(rule: :rule_results)
               .where(rules: { upstream: true }, rule_results: { id: nil })
               .delete_all
  end
end
