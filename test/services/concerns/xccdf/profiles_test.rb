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

    test 'correctly save value_overrides' do
      save_profiles

      profile1 = Profile.find_by(ref_id: 'xccdf_org.ssgproject.content_profile_pci-dss')
      profile2 = Profile.find_by(ref_id: 'xccdf_org.ssgproject.content_profile_standard')

      expected_overrides = {
        send(:value_definition_for, ref_id: 'xccdf_org.ssgproject.content_value_var_auditd_num_logs').id => '5',
        send(:value_definition_for, ref_id: 'xccdf_org.ssgproject.content_value_sshd_idle_timeout_value').id => '900',
        send(:value_definition_for, ref_id: 'xccdf_org.ssgproject.content_value_var_password_pam_minlen').id => '7',
        send(:value_definition_for, ref_id: 'xccdf_org.ssgproject.content_value_var_multiple_time_servers').id =>
          '0.rhel.pool.ntp.org,1.rhel.pool.ntp.org,2.rhel.pool.ntp.org,3.rhel.pool.ntp.org',
        send(:value_definition_for, ref_id: 'xccdf_org.ssgproject.content_value_var_password_pam_minclass').id => '2',
        send(:value_definition_for, ref_id: 'xccdf_org.ssgproject.content_value_var_password_pam_unix_remember').id =>
          '4',
        send(:value_definition_for, ref_id:
          'xccdf_org.ssgproject.content_value_var_accounts_maximum_age_login_defs').id => '90',
        send(:value_definition_for, ref_id:
          'xccdf_org.ssgproject.content_value_var_account_disable_post_pw_expiration').id => '90',
        send(:value_definition_for, ref_id:
          'xccdf_org.ssgproject.content_value_var_accounts_passwords_pam_faillock_deny').id => '6',
        send(:value_definition_for, ref_id:
          'xccdf_org.ssgproject.content_value_var_accounts_passwords_pam_faillock_unlock_time').id => '1800'
      }

      assert_equal expected_overrides, profile1.value_overrides
      assert_equal 0, profile2.value_overrides.length
    end
  end
end
