# frozen_string_literal: true

require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:ref_id).scoped_to(:benchmark_id)
  should validate_presence_of :ref_id

  setup do
    fake_report = file_fixture('xccdf_report.xml').read
    @op_rules = OpenscapParser::TestResultFile.new(fake_report).benchmark.rules

    account = FactoryBot.create(:account)
    @profile = FactoryBot.create(
      :profile,
      :with_rules,
      account: account,
      rule_count: 1
    )

    @rule = @profile.rules.first

    @host = FactoryBot.create(:host, org_id: account.org_id)
  end

  test 'creates rules from openscap_parser Rule object' do
    rule_group = FactoryBot.create(:rule_group, benchmark: @profile.benchmark)
    assert Rule.from_openscap_parser(@op_rules.first,
                                     benchmark_id: @profile.benchmark.id,
                                     rule_group_id: rule_group.id).save
  end

  test 'host one is not compliant?' do
    assert_not @rule.compliant?(@host, @profile)
  end

  test 'host one is compliant?' do
    tr = FactoryBot.create(:test_result, profile: @profile, host: @host)
    FactoryBot.create(:rule_result, rule: @rule, test_result: tr, host: @host)

    assert @rule.compliant?(@host, @profile)
  end

  test 'rule is found with_references' do
    rr = FactoryBot.create(:rule_reference, rules: [@rule])

    assert Rule.with_references(rr.label)
               .include?(@rule),
           'Expected rule not found by references'
  end

  test 'rule is identified properly as canonical' do
    rule = FactoryBot.create(:rule, benchmark: @profile.benchmark)

    assert_not rule.canonical?,
               'Rule :one should not be canonical to start'
    rule.update!(profiles: [@profile.parent_profile])
    assert rule.canonical?, 'Rule :one should be canonical'
  end

  test 'canonical rules are found via canonical scope' do
    @rule.update(profiles: [])
    assert_empty Rule.canonical, 'No canonical rules should exist'
    @rule.update(profiles: [@profile.parent_profile])
    assert_equal [@rule], Rule.canonical
  end

  test 'rule generates remediation issue id if remediation is available' do
    rule = @profile.rules.first
    rule.update!(ref_id: 'MyStringOne', remediation_available: true)
    @profile.test_results.destroy_all
    @profile.parent_profile.update!(
      ref_id: 'xccdf_org.ssgproject.content_profile_profile1'
    )

    assert_equal rule.remediation_issue_id, 'ssg:rhel7|profile1|MyStringOne'
  end

  test 'rule does not generate remediation issue id if remediation is not available' do
    rule = @profile.rules.first
    rule.update!(ref_id: 'MyStringOne', remediation_available: false)
    @profile.test_results.destroy_all
    @profile.parent_profile.update!(
      ref_id: 'xccdf_org.ssgproject.content_profile_profile1'
    )

    assert_nil rule.remediation_issue_id
  end

  test 'rule generates remediation issue id for RHEL8' do
    @profile.benchmark.update!(
      ref_id: 'xccdf_org.ssgproject.content_benchmark_RHEL-8'
    )

    @profile.parent_profile.update!(
      ref_id: 'xccdf_org.ssgproject.content_profile_profile1'
    )

    @rule.update!(
      ref_id: 'hello',
      remediation_available: true
    )

    assert_equal @rule.remediation_issue_id, 'ssg:rhel8|profile1|hello'
  end

  test 'rule empty remediation issue id for a rule without a profile' do
    @rule.update(profiles: [])
    assert_nil @rule.remediation_issue_id
  end
end
