# frozen_string_literal: true

module Xccdf
  # Methods related to saving TestResult from openscap_parser
  module TestResult
    delegate :score, to: :@op_test_result

    def save_test_result
      @test_result = ::V2::TestResult.create!(
        system: @system, tailoring: tailoring,
        report_id: @tailoring&.policy_id,
        supported: supported?, score: score,
        failed_rule_count: selected_op_rule_results&.count { |rr| ::V2::RuleResult::FAILED.include?(rr.result) }.to_i,
        start_time: @op_test_result.start_time.in_time_zone,
        end_time: @op_test_result.end_time.in_time_zone
      )

      delete_old_test_results if @test_result.persisted?

      @test_result
    end

    def delete_old_test_results
      old_test_results = ::V2::TestResult.left_outer_joins(tailoring: :policy)
                                         .where(tailorings: { policy_id: @tailoring.policy_id },
                                                system: @system)
                                         .where.not(id: @test_result.id)

      old_ids = old_test_results.pluck(:id)
      return if old_ids.empty?

      ::V2::RuleResult.where(test_result_id: old_ids).delete_all
      ::V2::TestResult.where(id: old_ids).delete_all
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
