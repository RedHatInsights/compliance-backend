# frozen_string_literal: true

module Xccdf
  # Methods related to saving TestResult from openscap_parser
  module TestResult
    EMPTY_SCORE = 0.0

    delegate :score, to: :@op_test_result

    def save_test_result
      @test_result = ::TestResult.create!(
        system: @system, tailoring: tailoring,
        report_id: @tailoring&.policy_id,
        supported: supported?, score: recomputed_score, mismatched: version_mismatched?,
        failed_rule_count: countable_op_rule_results.count { |rr| ::RuleResult::FAILED.include?(rr.result) },
        start_time: @op_test_result.start_time.in_time_zone,
        end_time: @op_test_result.end_time.in_time_zone
      )

      delete_old_test_results if @test_result.persisted?

      @test_result
    end

    def delete_old_test_results
      old_test_results = ::TestResult.left_outer_joins(tailoring: :policy)
                                     .where(tailorings: { policy_id: @tailoring.policy_id },
                                            system: @system)
                                     .where.not(id: @test_result.id)

      old_ids = old_test_results.pluck(:id)
      return if old_ids.empty?

      ::RuleResult.where(test_result_id: old_ids).delete_all
      ::TestResult.where(id: old_ids).delete_all
    end

    def recomputed_score
      return score unless version_mismatched?

      countable = countable_op_rule_results
      return EMPTY_SCORE if countable.empty?

      passed = countable.count { |rr| ::RuleResult::PASSED.include?(rr.result) }
      (passed.to_f / countable.size * 100).round(2)
    end

    def countable_op_rule_results
      @countable_op_rule_results ||= begin
        results = selected_op_rule_results || []
        if version_mismatched?
          matched = rule_ids.keys.to_set
          results.select { |rr| matched.include?(rr.id) }
        else
          results
        end
      end
    end

    def supported?
      SupportedSsg.supported?(
        ssg_version: security_guide.version,
        os_major_version: @system.os_major_version,
        os_minor_version: @system.os_minor_version
      )
    end
  end
end
