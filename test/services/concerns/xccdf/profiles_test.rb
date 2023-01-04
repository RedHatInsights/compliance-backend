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
    include Xccdf::ValueDefinitions

    setup do
      @account = FactoryBot.create(:account)
      @host = FactoryBot.create(:host, org_id: @account.org_id)
      @benchmark = FactoryBot.create(:canonical_profile, :with_rules).benchmark
      parser = OpenscapParser::TestResultFile.new(
        file_fixture('rhel-xccdf-report.xml').read
      )
      @op_profiles = parser.benchmark.profiles
      @op_value_definitions = parser.benchmark.values
      @op_test_result = parser.test_result
      save_value_definitions
    end

    test 'save_profiles' do
      assert_difference('Profile.count', 10) do
        save_profiles
      end

      assert_no_difference('Profile.count') do
        save_profiles
      end
    end

    test 'updates value_overrides' do
      save_profiles

      Profile.update(value_overrides: {})
      assert_equal Profile.where(value_overrides: {}).count, 11

      @profiles = nil
      @new_profiles = nil
      @old_profiles = nil

      save_profiles

      assert_equal Profile.where.not(value_overrides: {}).count, 9
    end
  end
end
