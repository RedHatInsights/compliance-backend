# frozen_string_literal: true

require 'test_helper'
require 'xccdf/profiles'
require 'xccdf/profile_os_minor_versions'

module Xccdf
  # A class to test Xccdf::ProfileOsMinorVersions
  class ProfileOsMinorVersionsTest < ActiveSupport::TestCase
    # Mock class for testing
    class Mock
      include Xccdf::Datastreams
      include Xccdf::Benchmarks
      include Xccdf::Profiles
      include Xccdf::ValueDefinitions
      include Xccdf::ProfileOsMinorVersions

      # attr_reader :benchmark

      def initialize(datastream_filename)
        @op_benchmark = op_datastream_file(datastream_filename).benchmark
        @op_profiles = @op_benchmark.profiles
        @op_value_definitions = @op_benchmark.values
      end
    end

    setup do
      @mock = Mock.new(file_fixture('ssg-rhel7-ds.xml'))
      @mock.save_benchmark
      @mock.save_value_definitions
      @mock.save_profiles
    end

    test 'save the support matrix' do
      SupportedSsg.expects(:by_ssg_version).returns(
        @mock.benchmark.version => [
          OpenStruct.new(
            os_major_version: @mock.benchmark.os_major_version,
            os_minor_version: '4'
          ),
          OpenStruct.new(
            os_major_version: @mock.benchmark.os_major_version,
            os_minor_version: '5'
          )
        ]
      ).at_least_once

      @mock.save_profile_os_minor_versions

      assert_equal(ProfileOsMinorVersion.count, @mock.profiles.count * 2)
    end

    test 'removes old records from the support matrix' do
      SupportedSsg.expects(:by_ssg_version).returns(
        @mock.benchmark.version => [
          OpenStruct.new(
            os_major_version: @mock.benchmark.os_major_version,
            os_minor_version: '4'
          )
        ]
      ).at_least_once

      @mock.save_profile_os_minor_versions
      assert_equal(ProfileOsMinorVersion.where(os_minor_version: 4).count, @mock.profiles.count)
      assert_equal(ProfileOsMinorVersion.where(os_minor_version: 5).count, 0)

      SupportedSsg.unstub(:by_ssg_version)
      SupportedSsg.expects(:by_ssg_version).returns(
        @mock.benchmark.version => [
          OpenStruct.new(
            os_major_version: @mock.benchmark.os_major_version,
            os_minor_version: '5'
          )
        ]
      ).at_least_once

      @mock.save_profile_os_minor_versions
      assert_equal(ProfileOsMinorVersion.where(os_minor_version: 4).count, 0)
      assert_equal(ProfileOsMinorVersion.where(os_minor_version: 5).count, @mock.profiles.count)
    end
  end
end
