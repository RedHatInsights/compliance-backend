# frozen_string_literal: true

require 'test_helper'
require 'xccdf/profiles'

module Xccdf
  # A class to test Xccdf::Profiles
  class ProfileRuleGroupsTest < ActiveSupport::TestCase
    include Xccdf::ProfileRuleGroups

    setup do
      @account = FactoryBot.create(:account)
      @host = FactoryBot.create(:host, account: @account.account_number)
      @benchmark = FactoryBot.create(:canonical_profile).benchmark
      parser = OpenscapParser::TestResultFile.new(
        file_fixture('xccdf_report.xml').read
      )
      @op_profiles = parser.benchmark.profiles
      @profiles = @op_profiles.map do |op_profile|
        ::Profile.from_openscap_parser(op_profile, benchmark_id: @benchmark&.id)
      end
      ::Profile.import!(@profiles, ignore: true)
      @op_rule_groups = parser.benchmark.groups
      @rule_groups = @op_rule_groups.map do |op_rule_group|
        ::RuleGroup.from_openscap_parser(op_rule_group, benchmark_id: @benchmark&.id)
      end
      ::RuleGroup.import!(@rule_groups, ignore: true)
      @op_rules = parser.benchmark.rules
      @rules = @op_rules.map do |op_rule|
        ::Rule.from_openscap_parser(op_rule, benchmark_id: @benchmark&.id)
      end
      ::Rule.import!(@rules, ignore: true)
    end

    test 'saves profile rule groups only once' do
      assert_difference('ProfileRuleGroup.count', 4) do
        save_profile_rule_groups
      end

      assert_no_difference('ProfileRuleGroup.count') do
        save_profile_rule_groups
      end
    end

    test 'updates profile rule group connections' do
      rule_group1 = FactoryBot.create(:rule_group, benchmark: @benchmark)
      rule_group2 = ::RuleGroup.from_openscap_parser(
        @op_rule_groups.find do |rule_group|
          rule_group.id == 'xccdf_org.ssgproject.content_group_accounts-physical'
        end,
        benchmark_id: @benchmark&.id
      )
      @profiles.first.update(rule_groups: [rule_group1, rule_group2])

      assert_difference('ProfileRuleGroup.count', 2) do
        save_profile_rule_groups
      end

      assert_nil ProfileRuleGroup.find_by(rule_group: rule_group1, profile: @profiles.first)
      assert ProfileRuleGroup.find_by(rule_group: rule_group2, profile: @profiles.first)
    end
  end
end
