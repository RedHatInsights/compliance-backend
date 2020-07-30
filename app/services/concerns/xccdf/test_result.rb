# frozen_string_literal: true

module Xccdf
  # Methods related to saving TestResult from openscap_parser
  module TestResult
    def save_test_result
      @test_result = ::TestResult.create!(
        host: @host,
        profile: @host_profile,
        score: @op_test_result.score,
        start_time: @op_test_result.start_time.in_time_zone,
        end_time: @op_test_result.end_time.in_time_zone
      )

      delete_old_test_results if @test_result.persisted?

      @test_result
    end

    def delete_old_test_results
      ::TestResult.where(host: @host, profile: @host_profile)
                  .where.not(id: @test_result.id)
                  .destroy_all
    end
  end
end
