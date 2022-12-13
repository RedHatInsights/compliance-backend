# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rule_groups'

class RuleGroupsTest < ActiveSupport::TestCase
  include Xccdf::Profiles
  include Xccdf::Rules
  include Xccdf::RuleGroups
  include Xccdf::ProfileRules

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

  test 'update ancestry column for rule group with ancestors' do
    save_rule_groups

    assert_equal 228, @rule_groups.reject { |rg| rg.ancestry == '' }.count
    assert_equal 4, @rule_groups.select { |rg| rg.ancestry == '' }.count

    rg_with_ancestors = @rule_groups.select { |rg| rg.ref_id == 'xccdf_org.ssgproject.content_group_root_logins' }.first
    parent1 = rg_with_ancestors.parent
    parent2 = parent1.parent
    root = parent2.parent
    rg_ancestor_ids = rg_with_ancestors.ancestors.map(&:id)

    assert_equal "#{root.id}/#{parent2.id}/#{parent1.id}", rg_with_ancestors.ancestry
    assert_nil root.parent
    assert_equal '', @rule_groups[0].ancestry
    assert_equal @rule_groups[2].parent.id.to_s, @rule_groups[2].ancestry
    assert_includes rg_ancestor_ids, root.id
    assert_includes rg_ancestor_ids, parent2.id
    assert_includes rg_ancestor_ids, parent1.id
  end

  test 'saves rule groups only once' do
    assert_difference('RuleGroup.count', 232) do
      save_rule_groups
    end
    assert_equal 228, @rule_groups.reject { |rg| rg.ancestry == '' }.count
    assert_equal 4, @rule_groups.select { |rg| rg.ancestry == '' }.count

    @new_rule_groups = nil

    assert_no_difference('RuleGroup.count') do
      save_rule_groups
    end
    assert_equal 228, @rule_groups.reject { |rg| rg.ancestry == '' }.count
    assert_equal 4, @rule_groups.select { |rg| rg.ancestry == '' }.count
  end

  test 'reorders rule groups when needed' do
    save_rule_groups
    before = @benchmark.rule_groups.order(:precedence).pluck(:ref_id)

    @rule_groups = nil
    @old_rule_groups = nil
    @new_rule_groups = nil
    @cached_rule_groups = nil
    @op_rule_groups.reverse!

    save_rule_groups

    after = @benchmark.rule_groups.order(:precedence).pluck(:ref_id)

    assert_equal before, after.reverse
  end
end
