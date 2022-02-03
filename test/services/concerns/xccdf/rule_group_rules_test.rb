# frozen_string_literal: true

require 'test_helper'
require 'xccdf/rule_group_rules'
require 'xccdf/rule_groups'
require 'xccdf/rule_references_rules'

class RuleGroupRulesTest < ActiveSupport::TestCase
  include Xccdf::Profiles
  include Xccdf::Rules
  include Xccdf::RuleGroupRules
  include Xccdf::RuleGroups
  include Xccdf::ProfileRules
  include Xccdf::RuleReferences
  include Xccdf::RuleReferencesRules

  attr_accessor :benchmark, :account, :op_profiles, :op_rules, :rules,
                :rule_groups, :op_rule_groups, :rule_groups_with_parents,
                :op_rules_and_rule_groups, :rule_group_rules

  context 'parent-child relationship between rule group and rule' do
    setup do
      @account = FactoryBot.create(:account)
      @host = FactoryBot.create(:host, account: @account.account_number)
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
        ::Rule.from_openscap_parser(op_rule, benchmark_id: @benchmark&.id)
      end
      ::Rule.import!(@rules, ignore: true)
      @op_rules_and_rule_groups = @op_rules + @op_rule_groups
    end

    should 'save rule group rules for parent-child relationship between rule group and rule' do
      assert_difference('RuleGroupRule.count', 367) do
        save_rule_group_rules
      end
    end

    should 'save rule group rules for parent-child relationship between rule group and rule only once' do
      assert_difference('RuleGroupRule.count', 367) do
        save_rule_group_rules
      end

      assert_no_difference('RuleGroupRule.count') do
        save_rule_group_rules
      end
    end

    should 'remove rule_group_rules that are no longer relevent' do
      rules_by_ref_id = @rules.index_by(&:ref_id)
      rule = rules_by_ref_id['xccdf_org.ssgproject.content_rule_install_PAE_kernel_on_x86-32']
      rule_group_rule = RuleGroupRule.create!(rule_id: rule.id,
                                              rule_group_id: @rule_groups.first.id)
      assert_not_nil RuleGroupRule.where(id: rule_group_rule.id).first

      save_rule_group_rules

      assert_not_nil RuleGroupRule.where(rule_id: rule.id).first
      assert_nil RuleGroupRule.where(id: rule_group_rule.id).first
    end
  end
end
