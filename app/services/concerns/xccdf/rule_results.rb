# frozen_string_literal: true

module Xccdf
  # Methods related to saving RuleResults from openscap_parser
  module RuleResults
    def save_rule_results
      @rule_results = selected_rule_results.map do |op_rule_result|
        ::RuleResult.from_openscap_parser(
          op_rule_result,
          rule_ids: rule_ids, host_id: @host.id,
          start_time: @op_test_result.start_time.in_time_zone,
          end_time: @op_test_result.end_time.in_time_zone
        )
      end

      ::RuleResult.import!(@rule_results.select(&:new_record?), ignore: true)
    end

    private

    def rule_ids
      @rule_ids = ::Rule.where(
        ref_id: selected_rule_results.map(&:id),
        benchmark_id: @benchmark&.id
      ).pluck(:ref_id, :id).to_h
    end

    def selected_rule_results
      @op_rule_results.reject do |rule_result|
        rule_result.result == 'notselected'
      end
    end
  end
end
