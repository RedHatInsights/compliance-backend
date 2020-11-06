# frozen_string_literal: true

require 'test_helper'
require 'xccdf/test_result'

class TestResultTest < ActiveSupport::TestCase
  class Mock
    include Xccdf::TestResult

    attr_accessor :host, :host_profile, :op_test_result, :test_result
  end

  setup do
    ProfileHost.create!(host: hosts(:one), profile: profiles(:one))
    @end_time = DateTime.now
    @mock = Mock.new
    @mock.host = hosts(:one)
    @mock.host_profile = profiles(:one)
    @mock.op_test_result = OpenStruct.new(score: 30,
                                          start_time: @end_time - 2.minutes,
                                          end_time: @end_time)
  end

  test 'old test results are destroyed and replaced by the new test result' do
    TestResult.where(host: hosts(:one), profile: profiles(:one)).destroy_all

    assert_difference('TestResult.count' => 2) do
      TestResult.create!(host: hosts(:one),
                         profile: profiles(:one),
                         end_time: @end_time - 3.minutes)

      TestResult.create!(host: hosts(:one),
                         profile: profiles(:one),
                         end_time: @end_time - 8.minutes)
    end

    assert_difference('TestResult.count' => -1) do
      @mock.save_test_result
    end
  end

  test 'old test results within a policy replaced by the new test result' do
    profiles(:two).update!(policy_object: policies(:one),
                           account: accounts(:test))
    profiles(:one).update!(policy_object: policies(:one),
                           account: accounts(:test))
    TestResult.where(host: hosts(:one), profile: profiles(:one)).destroy_all

    assert_difference('TestResult.count' => 2) do
      TestResult.create!(host: hosts(:one),
                         profile: profiles(:one),
                         end_time: @end_time - 3.minutes)

      TestResult.create!(host: hosts(:one),
                         profile: profiles(:two),
                         end_time: @end_time - 8.minutes)
    end

    assert_difference('TestResult.count' => -1) do
      @mock.save_test_result
    end
    assert_equal TestResult.find_by(host: hosts(:one)), @mock.test_result
  end

  test 'old external test results are replaced by the new test result' do
    profiles(:two).update!(policy_object: nil, account: accounts(:test))
    profiles(:one).update!(policy_object: nil, account: accounts(:test))
    TestResult.where(host: hosts(:one), profile: profiles(:one)).destroy_all

    assert_difference('TestResult.count' => 2) do
      TestResult.create!(host: hosts(:one),
                         profile: profiles(:one),
                         end_time: @end_time - 3.minutes)

      TestResult.create!(host: hosts(:one),
                         profile: profiles(:two),
                         end_time: @end_time - 8.minutes)
    end

    assert_difference('TestResult.count' => -1) do
      @mock.save_test_result
    end
    assert_equal TestResult.find_by(host: hosts(:one)), @mock.test_result
  end
end
