# frozen_string_literal: true

require 'test_helper'
require 'xccdf/test_result'

class TestResultTest < ActiveSupport::TestCase
  class Mock
    include Xccdf::TestResult

    attr_accessor :host, :host_profile, :op_test_result
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
end
