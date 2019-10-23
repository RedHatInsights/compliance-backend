# frozen_string_literal: true

require 'test_helper'
require 'xccdf/profiles'

module Xccdf
  # A class to test Xccdf::Profiles
  class ProfilesTest < ActiveSupport::TestCase
    def test_result
      OpenStruct.new(id: ['xccdf_org.ssgproject.content_profile_standard'])
    end

    def report_description
      'description'
    end

    include Xccdf::Profiles

    setup do
      @account = accounts(:test)
      @host = hosts(:one)
      @benchmark = benchmarks(:one)
      parser = OpenscapParser::TestResultFile.new(
        file_fixture('xccdf_report.xml').read
      )
      @op_profiles = parser.benchmark.profiles
      @op_test_result = parser.test_result
    end

    test 'save_profiles' do
      assert_difference('Profile.count', 1) do
        save_profiles
      end

      assert_no_difference('Profile.count') do
        save_profiles
      end
    end
  end
end
