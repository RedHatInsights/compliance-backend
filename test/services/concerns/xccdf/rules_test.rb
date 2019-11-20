# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rules'

class RulesTest < ActiveSupport::TestCase
  class MockParser
    include Xccdf::Profiles
    include Xccdf::Rules
    include Xccdf::ProfileRules
    include Xccdf::RuleReferences

    attr_accessor :benchmark, :account, :op_profiles, :op_rules, :rules

    def initialize(report_contents)
      test_result_file = OpenscapParser::TestResultFile.new(report_contents)
      @op_benchmark = test_result_file.benchmark
      @op_test_result = test_result_file.test_result
      @op_rules = @op_benchmark.rules
      @op_profiles = @op_benchmark.profiles
    end
  end

  setup do
    @mock = MockParser.new(file_fixture('xccdf_report.xml').read)
    @mock.benchmark = benchmarks(:one)
    @mock.account = accounts(:test)
  end

  test 'save all rules as new' do
    assert_difference('Rule.count', 367) do
      @mock.save_rules
    end
  end

  test 'returns only rules saved with the report' do
    original_rule = ::Rule.from_openscap_parser(@mock.op_rules.sample)
    @mock.save_rules
    assert(@mock.rules.select { |rule| rule.id == original_rule.ref_id })
    assert ::Rule.where(ref_id: original_rule.ref_id).present?
  end

  test 'does not return rules in the report that were saved previously' do
    rule = Rule.from_openscap_parser(@mock.op_rules.sample,
                                     benchmark_id: @mock.benchmark.id)
    assert rule.save
    @mock.save_rules
    assert_not_includes @mock.rules, rule
  end

  test 'save all rules and add profiles to pre existing one' do
    profile = Profile.create(ref_id: @mock.op_profiles.first.id,
                             name: @mock.op_profiles.first.name,
                             benchmark: @mock.benchmark)
    assert_no_difference('Profile.count') do # only 1 profile in this benchmark
      @mock.save_profiles
    end
    rule = Rule.from_openscap_parser(@mock.op_rules.find do |r|
      r.id == @mock.op_profiles.first.selected_rule_ids.first
    end, benchmark_id: @mock.benchmark.id)
    assert rule.save
    assert_difference('Rule.count', 366) do
      @mock.save_rules
    end

    @mock.rules << rule
    assert_difference('ProfileRule.count', 74) do
      @mock.save_profile_rules
    end

    assert_includes rule.profiles.pluck(:id), profile.id
  end
end
