# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rules'

class RulesTest < ActiveSupport::TestCase
  class Mock
    include Xccdf::Profiles
    include Xccdf::Rules
    include Xccdf::RuleGroupRules
    include Xccdf::RuleGroups
    include Xccdf::ProfileRules
    include Xccdf::RuleReferences

    attr_accessor :benchmark, :account, :op_profiles, :op_rules, :rules

    def initialize(report_contents)
      test_result_file = OpenscapParser::TestResultFile.new(report_contents)
      @op_benchmark = test_result_file.benchmark
      @op_test_result = test_result_file.test_result
      @op_rules = @op_benchmark.rules
      @op_profiles = @op_benchmark.profiles
      @op_rule_groups = @op_benchmark.groups
    end
  end

  setup do
    @mock = Mock.new(file_fixture('xccdf_report.xml').read)
    @mock.benchmark = FactoryBot.create(
      :canonical_profile, :with_rules
    ).benchmark
    @mock.account = FactoryBot.create(:account)
    @mock.save_rule_groups
  end

  test 'save all rules as new' do
    assert_difference('Rule.count', 367) do
      @mock.save_rules
    end
  end

  test 'returns rules saved in the report' do
    rule = Rule.from_openscap_parser(@mock.op_rules.sample,
                                     benchmark_id: @mock.benchmark.id)
    assert rule.save
    @mock.save_rules
    assert_includes @mock.rules, rule
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

    assert_difference('ProfileRule.count', 74) do
      @mock.save_profile_rules
    end

    assert_includes rule.profiles.pluck(:id), profile.id
  end

  test 'reorders rules when needed' do
    @mock.benchmark.rules.clear
    @mock.save_rules

    before = @mock.benchmark.rules.order(:precedence).pluck(:ref_id)

    @mock.instance_variable_set(:@rules, nil)
    @mock.instance_variable_set(:@op_rules, @mock.instance_variable_get(:@op_rules).reverse)
    @mock.save_rules

    after = @mock.benchmark.rules.order(:precedence).pluck(:ref_id)

    assert_equal before, after.reverse
  end
end
