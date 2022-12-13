# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rule_group_relationships'
require 'xccdf/rule_groups'

class RuleGroupRelationshipsTest < ActiveSupport::TestCase
  include Xccdf::Profiles
  include Xccdf::Rules
  include Xccdf::RuleGroups
  include Xccdf::ProfileRules
  include Xccdf::RuleGroupRelationships

  attr_accessor :benchmark, :account, :op_profiles, :op_rules, :rules,
                :rule_groups, :op_rule_groups, :rule_groups_with_parents,
                :op_rules_and_rule_groups

  context 'without any required or conflicting rules or rule groups' do
    setup do
      @account = FactoryBot.create(:account)
      @host = FactoryBot.create(:host, org_id: @account.org_id)
      @benchmark = FactoryBot.create(:canonical_profile).benchmark
      parser = OpenscapParser::TestResultFile.new(
        file_fixture('rhel-xccdf-report.xml').read
      )
      @op_rules = parser.benchmark.rules
      @op_rule_groups = parser.benchmark.groups
      @rule_groups = @op_rule_groups.map do |op_rule_group|
        ::RuleGroup.from_openscap_parser(op_rule_group, benchmark_id: @benchmark&.id)
      end
      ::RuleGroup.import!(@rule_groups, ignore: true)
      @rules = @op_rules.map do |op_rule|
        ::Rule.from_openscap_parser(op_rule, benchmark_id: @benchmark&.id, rule_group_id: @rule_groups.first.id)
      end
      ::Rule.import!(@rules, ignore: true)
      @op_rules_and_rule_groups = @op_rules + @op_rule_groups
    end

    should 'save no rule group relationships when there are no required or conflicting rules or rule groups' do
      assert_no_difference('RuleGroupRelationship.count') do
        save_rule_group_relationships
      end
    end

    should 'return empty array are no required rules or rule groups' do
      required_rule_group_relationships = send(:rule_group_relationships)
      assert_equal [], required_rule_group_relationships
    end
  end

  context 'with required and conflicting rules or rule groups' do
    setup do
      @account = FactoryBot.create(:account)
      @host = FactoryBot.create(:host, org_id: @account.org_id)
      @benchmark = FactoryBot.create(:canonical_profile).benchmark
      parser = OpenscapParser::TestResultFile.new(
        file_fixture('xccdf_report.xml').read
      )
      @op_rules = parser.benchmark.rules
      @op_rule_groups = parser.benchmark.groups
      @rule_groups = @op_rule_groups.map do |op_rule_group|
        ::RuleGroup.from_openscap_parser(op_rule_group, benchmark_id: @benchmark&.id)
      end
      ::RuleGroup.import!(@rule_groups, ignore: true)
      @rules = @op_rules.map do |op_rule|
        ::Rule.from_openscap_parser(op_rule, benchmark_id: @benchmark&.id, rule_group_id: @rule_groups.first.id)
      end
      ::Rule.import!(@rules, ignore: true)
      @op_rules_and_rule_groups = @op_rules + @op_rule_groups
    end

    should 'save rule group rules with required and conflicting rules and rule groups' do
      assert_difference('RuleGroupRelationship.count', 8) do
        save_rule_group_relationships
      end
    end

    should 'save rule group rules only once' do
      assert_difference('RuleGroupRelationship.count', 8) do
        save_rule_group_relationships
      end

      assert_no_difference('RuleGroupRelationship.count') do
        save_rule_group_relationships
      end
    end

    should 'save a rule group rule for all required rules or rule groups' do
      required_rule_group_relationships = send(:rule_group_relationships)
      assert_equal 8, required_rule_group_relationships.count
    end

    should 'delete rule_group_relationships that are no longer relevant' do
      rule_groups_by_ref_id = @rule_groups.index_by(&:ref_id)
      rg = rule_groups_by_ref_id['xccdf_org.ssgproject.content_group_disabling_squid']
      rgr = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_requires)
      rgr.update!(left: rg, right: @rules.first)
      assert_not_nil RuleGroupRelationship.where(id: rgr.id).first
      save_rule_group_relationships
      assert_nil RuleGroupRelationship.where(id: rgr.id).first
    end

    should 'not delete rule_group_relationships that are still relevant' do
      rule_groups_by_ref_id = @rule_groups.index_by(&:ref_id)
      rg = rule_groups_by_ref_id['xccdf_org.ssgproject.content_group_disabling_squid']
      required_rg = rule_groups_by_ref_id['xccdf_org.ssgproject.content_group_openstack']
      rgr = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_conflicts)
      rgr.update!(left: rg, right: required_rg)
      assert_not_nil RuleGroupRelationship.where(id: rgr.id).first
      save_rule_group_relationships
      assert_not_nil RuleGroupRelationship.where(id: rgr.id).first
    end
  end
end
