# frozen_string_literal: true

require 'test_helper'
require 'xccdf/profiles'

module Xccdf
  # A class to test Xccdf::Profiles
  class ProfileRulessTest < ActiveSupport::TestCase
    include Xccdf::ProfileRules

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
      @op_rules = parser.benchmark.rules
      @rules = @op_rules.map do |op_rule|
        ::Rule.from_openscap_parser(op_rule, benchmark_id: @benchmark&.id)
      end
      ::Rule.import!(@rules, ignore: true)
    end

    test 'saves profile rules only once' do
      assert_difference('ProfileRule.count', 74) do
        save_profile_rules
      end

      assert_no_difference('ProfileRule.count') do
        save_profile_rules
      end
    end

    test 'updates profile rule connections' do
      rule1 = FactoryBot.create(:rule, benchmark: @benchmark)
      rule2 = ::Rule.from_openscap_parser(
        @op_rules.find do |rule|
          rule.id == 'xccdf_org.ssgproject.content_rule_disable_prelink'
        end,
        benchmark_id: @benchmark&.id
      )
      @profiles.first.update(rules: [rule1, rule2])

      # TODO: dry-run on the destructive operation first
      # assert_difference('ProfileRule.count', 72) do
      save_profile_rules
      # end

      # assert_nil ProfileRule.find_by(rule: rule1, profile: @profiles.first)
      # assert ProfileRule.find_by(rule: rule2, profile: @profiles.first)
    end
  end
end
