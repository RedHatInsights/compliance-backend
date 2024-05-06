# frozen_string_literal: true

require 'test_helper'

class RulesTest < ActiveSupport::TestCase
  class Mock
    include Xccdf::Profiles
    include Xccdf::Rules
    include Xccdf::RuleGroups
    include Xccdf::ValueDefinitions
    include Xccdf::ProfileRules

    attr_accessor :benchmark, :account, :op_profiles, :op_rules

    def initialize(report_contents)
      test_result_file = OpenscapParser::TestResultFile.new(report_contents)
      @op_benchmark = test_result_file.benchmark
      @op_test_result = test_result_file.test_result
      @op_rules = @op_benchmark.rules
      @op_value_definitions = @op_benchmark.values
      @op_profiles = @op_benchmark.profiles
      @op_rule_groups = @op_benchmark.groups
    end
  end

  setup do
    @mock = Mock.new(file_fixture('xccdf_report.xml').read)
    @mock.benchmark = FactoryBot.create(
      :canonical_profile, :with_rules
    ).benchmark
    RuleReferencesContainer.delete_all
    @mock.account = FactoryBot.create(:account)
    @mock.save_rule_groups
    @mock.save_value_definitions
  end

  test 'save all rules as new' do
    assert_difference('Rule.count', 367) do
      @mock.save_rules
    end
  end

  test 'returns rules saved in the report' do
    rule = Rule.from_openscap_parser(@mock.op_rules.sample,
                                     benchmark_id: @mock.benchmark.id,
                                     rule_group_id: @mock.benchmark.rule_groups.first.id)
    assert rule.save
    @mock.save_rules
    assert_includes @mock.rules, rule
  end

  test 'correctly saves value_checks' do
    @mock.save_rules
    rule1 = Rule.find_by(ref_id: 'xccdf_org.ssgproject.content_rule_network_ipv6_disable_interfaces')
    rule2 = Rule.find_by(ref_id: 'xccdf_org.ssgproject.content_rule_sshd_set_idle_timeout')
    value1 = ValueDefinition.find_by(ref_id: 'xccdf_org.ssgproject.content_value_sshd_required')
    value2 = ValueDefinition.find_by(ref_id: 'xccdf_org.ssgproject.content_value_sshd_idle_timeout_value')

    assert_includes rule2.value_checks, value1.id
    assert_includes rule2.value_checks, value2.id
    assert_equal 2, rule2.value_checks.length
    assert_equal [], rule1.value_checks
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
    end, benchmark_id: @mock.benchmark.id, rule_group_id: @mock.benchmark.rule_groups.first.id)
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
    @mock.instance_variable_set(:@old_rules, nil)
    @mock.instance_variable_set(:@new_rules, nil)
    @mock.instance_variable_set(:@op_rules, @mock.instance_variable_get(:@op_rules).reverse)
    @mock.save_rules

    after = @mock.benchmark.rules.order(:precedence).pluck(:ref_id)

    assert_equal before, after.reverse
  end

  %i[description rationale severity].each do |field|
    test "updates #{field} field when needed" do
      @mock.benchmark.rules.clear
      @mock.save_rules

      rule = @mock.benchmark.rules.order(:precedence).first

      @mock.instance_variable_set(:@rules, nil)
      @mock.instance_variable_set(:@old_rules, nil)
      @mock.instance_variable_set(:@new_rules, nil)
      @mock.instance_variable_get(:@op_rules).first.instance_variable_set("@#{field}".to_sym, 'foobar')
      @mock.save_rules

      assert_equal rule.reload[field], 'foobar'
    end
  end

  test 'updates value_checks field when needed' do
    @mock.benchmark.rules.clear
    @mock.save_rules

    rule = @mock.benchmark.rules.order(:precedence).first

    assert_equal [], rule.value_checks

    value_ref_id = @mock.benchmark.value_definitions.first.ref_id
    value_id = @mock.benchmark.value_definitions.first.id

    @mock.instance_variable_set(:@rules, nil)
    @mock.instance_variable_set(:@old_rules, nil)
    @mock.instance_variable_set(:@new_rules, nil)
    @mock.instance_variable_get(:@op_rules).first.stubs(:values).returns([value_ref_id])

    @mock.save_rules

    assert_equal [value_id], rule.reload[:value_checks]
  end
end
