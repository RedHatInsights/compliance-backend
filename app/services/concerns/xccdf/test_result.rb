# frozen_string_literal: true

module Xccdf
  # Methods related to saving TestResult from openscap_parser
  module TestResult
    def save_test_result
      @test_result = ::TestResult.create!(
        host: @host,
        profile: @host_profile,
        supported: supported?,
        score: score,
        start_time: @op_test_result.start_time.in_time_zone,
        end_time: @op_test_result.end_time.in_time_zone
      )

      delete_old_test_results if @test_result.persisted?

      @test_result
    end

    def delete_old_test_results
      ::TestResult.left_outer_joins(profile: :policy)
                  .where(profiles: { policy: @host_profile.policy_id },
                         host: @host)
                  .where.not(id: @test_result.id)
                  .destroy_all
    end

    def score
      @op_test_result.score
    end

    def supported?
      SupportedSsg.supported?(
        ssg_version: @host_profile.ssg_version,
        os_major_version: @host.os_major_version,
        os_minor_version: @host.os_minor_version
      )
    end
  end
end
