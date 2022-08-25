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
    @host = FactoryBot.create(:host, org_id: @account.org_id)
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
    ::RuleGroup.import!(@rule_groups, ignore: true)
    assert_equal 0, @rule_groups.select(&:ancestry).count
    @rule_groups_with_parents = send(:rule_group_parents)
    ::RuleGroup.import!(@rule_groups_with_parents, on_duplicate_key_update: {
                          conflict_target: %i[ref_id benchmark_id],
                          columns: :all
                        })
    assert_equal 228, @rule_groups.select(&:ancestry).count
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
