# frozen_string_literal: true

module Xccdf
  # Methods related to saving RuleResults from openscap_parser
  module RuleResults
    def save_rule_results
      ::RuleResult.import!(rule_results.select(&:new_record?), ignore: true)
    end

    def rule_results
      @rule_results ||= selected_op_rule_results.map do |op_rule_result|
        ::RuleResult.from_openscap_parser(
          op_rule_result,
          test_result_id: @test_result.id, rule_id: rule_ids[op_rule_result.id],
          host_id: @host.id
        )
      end
    end

    def failed_rule_results
      ::RuleResult.where(id: rule_results).failed
    end

    def failed_rules
      ::Rule.joins(:rule_results)
            .where(rule_results: failed_rule_results)
            .distinct
    end

    def selected_op_rule_results
      @op_rule_results.reject do |rule_result|
        ::RuleResult::NOT_SELECTED.include? rule_result.result
      end
    end

    def test_result_rules_unknown
      selected_op_rule_results.map(&:id) - rule_ids.keys
    end

    private

    def rule_ids
      @rule_ids ||= Rule.where(
        benchmark: benchmark, ref_id: selected_op_rule_results.map(&:id)
      ).pluck(:ref_id, :id).to_h
    end
  end
end
