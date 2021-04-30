# frozen_string_literal: true

require 'test_helper'
require 'xccdf/test_result'

class TestResultTest < ActiveSupport::TestCase
  class Mock
    include Xccdf::TestResult

    attr_accessor :host, :host_profile, :op_test_result, :test_result
  end

  setup do
    @account = FactoryBot.create(:account)
    @end_time = DateTime.now
    @mock = Mock.new
    @mock.host_profile = FactoryBot.create(:profile, account: @account)
    @mock.host = FactoryBot.create(:host, account: @account.account_number)
    @mock.op_test_result = OpenStruct.new(score: 30,
                                          start_time: @end_time - 2.minutes,
                                          end_time: @end_time)
  end

  test 'old test results are destroyed and replaced by the new test result' do
    assert_difference('TestResult.count' => 2) do
      TestResult.create!(
        host: @mock.host,
        profile: @mock.host_profile,
        end_time: @end_time - 3.minutes
      )

      TestResult.create!(
        host: @mock.host,
        profile: @mock.host_profile,
        end_time: @end_time - 8.minutes
      )
    end

    assert_difference('TestResult.count' => -1) do
      @mock.save_test_result
    end
  end

  test 'old test results within a policy replaced by the new test result' do
    p2 = FactoryBot.create(
      :profile,
      policy: @mock.host_profile.policy,
      account: @account
    )

    assert_difference('TestResult.count' => 2) do
      TestResult.create!(
        host: @mock.host,
        profile: @mock.host_profile,
        end_time: @end_time - 3.minutes
      )

      TestResult.create!(
        host: @mock.host,
        profile: p2,
        end_time: @end_time - 8.minutes
      )
    end

    assert_difference('TestResult.count' => -1) do
      @mock.save_test_result
    end
    assert_equal TestResult.find_by(host: @mock.host), @mock.test_result
  end

  context 'supportability' do
    should 'default to supported' do
      tr = FactoryBot.create(
        :test_result,
        profile: @mock.host_profile,
        host: @mock.host
      )
      assert tr.supported
    end

    should 'mark hosts without an OS as unsupported' do
      @mock.host.stubs(:os_major_version)
      @mock.host.stubs(:os_minor_version)

      @mock.save_test_result

      test_result = TestResult.find_by(host: @mock.host,
                                       profile: @mock.host_profile)
      assert_not test_result.supported
    end

    should 'mark hosts with a mismatched OS as unsupported' do
      @mock.host.expects(:os_major_version).returns(7)
      @mock.host.expects(:os_minor_version).returns(4)
      assert_not_includes SupportedSsg.ssg_versions_for_os(7, 4),
                          @mock.host_profile.ssg_version

      @mock.save_test_result

      test_result = TestResult.find_by(host: @mock.host,
                                       profile: @mock.host_profile)
      assert_not test_result.supported
    end

    should 'mark hosts with a matched OS as supported' do
      @mock.host.expects(:os_major_version).returns(7)
      @mock.host.expects(:os_minor_version).returns(4)
      @mock.host_profile.benchmark.update!(version: '0.1.33')
      assert_includes SupportedSsg.ssg_versions_for_os(7, 4),
                      @mock.host_profile.ssg_version

      @mock.save_test_result

      test_result = TestResult.find_by(host: @mock.host,
                                       profile: @mock.host_profile)
      assert test_result.supported
    end
  end
end
