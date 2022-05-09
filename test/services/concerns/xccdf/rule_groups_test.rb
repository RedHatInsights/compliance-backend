# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rule_groups'

class RuleGroupsTest < ActiveSupport::TestCase
  include Xccdf::Profiles
  include Xccdf::Rules
  include Xccdf::RuleGroupRules
  include Xccdf::RuleGroups
  include Xccdf::ProfileRules
  include Xccdf::RuleReferences

  attr_accessor :benchmark, :account, :op_profiles, :op_rules, :rules,
                :rule_groups, :op_rule_groups, :rule_groups_with_parents

  setup do
    @account = FactoryBot.create(:account)
    @host = FactoryBot.create(:host, account: @account.account_number)
    @benchmark = FactoryBot.create(:canonical_profile).benchmark
    parser = OpenscapParser::TestResultFile.new(
      file_fixture('rhel-xccdf-report.xml').read
    )
    @op_rules = parser.benchmark.rules
    @op_rule_groups = parser.benchmark.groups
  end

  test 'save all rule groups as new' do
    assert_difference('RuleGroup.count', 232) do
      save_rule_groups
    end
  end

  test 'returns rule groups saved in the report' do
    rule_group = RuleGroup.from_openscap_parser(@op_rule_groups.sample,
                                                benchmark_id: @benchmark.id)
    assert rule_group.save
    save_rule_groups
    assert_includes @rule_groups, rule_group
  end

  test 'update ancestry column for rule group with parents' do
    @rule_groups = @op_rule_groups.map do |op_rule_group|
      ::RuleGroup.from_openscap_parser(op_rule_group, benchmark_id: @benchmark&.id)
    end

    ::RuleGroup.import!(@rule_groups.select(&:new_record?), ignore: true)

    rule_group = @rule_groups.select { |rg| rg.ref_id == 'xccdf_org.ssgproject.content_group_remediation_functions' }
                             .first
    rule_group.update(ref_id: 'xccdf_org.ssgproject.content_group_remediation_functions')
    rule_group.update(parent: RuleGroup.second)

    assert_equal rule_group.parent, RuleGroup.second
    assert_equal 1, @rule_groups.select(&:ancestry).count

    send(:rule_group_parents)

    assert_nil rule_group.parent
    assert_equal rule_group.is_root?, true
    assert_equal 228, @rule_groups.select(&:ancestry).count

    rule_groups_by_ref_id = @rule_groups.index_by(&:ref_id)
    rule_group = rule_groups_by_ref_id['xccdf_org.ssgproject.content_group_principle-encrypt-transmitted-data']

    assert_equal rule_group.ancestors.map(&:ref_id), ['xccdf_org.ssgproject.content_group_intro',
                                                      'xccdf_org.ssgproject.content_group_general-principles']

    rg1_id = rule_groups_by_ref_id['xccdf_org.ssgproject.content_group_intro'].id
    rg2_id = rule_groups_by_ref_id['xccdf_org.ssgproject.content_group_general-principles'].id
    assert_equal rule_group.ancestry, "#{rg1_id}/#{rg2_id}"
  end

  test 'saves rule groups only once' do
    assert_difference('RuleGroup.count', 232) do
      save_rule_groups
    end

    assert_no_difference('RuleGroup.count') do
      save_rule_groups
    end
  end
end
