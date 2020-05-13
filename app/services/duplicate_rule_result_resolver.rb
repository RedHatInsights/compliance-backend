# frozen_string_literal: true

# A service class to merge duplicate RuleResult objects
class DuplicateRuleResultResolver
  class << self
    def run!
      @rule_results = nil
      duplicate_rule_results.find_each do |rule_result|
        if existing_rule_result(rule_result)
          migrate_rule_result(existing_rule_result(rule_result), rule_result)
        else
          self.existing_rule_result = rule_result
        end
      end
    end

    private

    def existing_rule_result(rule_result)
      rule_results[[rule_result.host_id, rule_result.rule_id,
                    rule_result.test_result_id]]
    end

    def existing_rule_result=(rule_result)
      rule_results[[rule_result.host_id, rule_result.rule_id,
                    rule_result.test_result_id]] = rule_result
    end

    def rule_results
      @rule_results ||= {}
    end

    def duplicate_rule_results
      RuleResult.joins(
        "JOIN (#{grouped_nonunique_rule_result_tuples.to_sql}) as rr on "\
        'rule_results.host_id = rr.host_id AND '\
        'rule_results.rule_id = rr.rule_id AND '\
        'rule_results.test_result_id = rr.test_result_id'
      )
    end

    def grouped_nonunique_rule_result_tuples
      RuleResult.select(:host_id, :rule_id, :test_result_id)
                .group(:host_id, :rule_id, :test_result_id)
                .having('COUNT(id) > 1')
    end

    def migrate_rule_result(_existing_rr, duplicate_rr)
      duplicate_rr.destroy
    end
  end
end
