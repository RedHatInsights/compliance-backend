# frozen_string_literal: true

require 'test_helper'

class RuleGroupRuleTest < ActiveSupport::TestCase
  should belong_to(:rule)
  should belong_to(:rule_group)

  setup do
    fake_report = file_fixture('xccdf_report.xml').read
    @op_benchmark = OpenscapParser::TestResultFile.new(fake_report).benchmark
    @op_rule_groups = @op_benchmark.groups

    account = FactoryBot.create(:account)
    @profile = FactoryBot.create(
      :profile,
      account: account
    )
    @rule_group_1 = FactoryBot.create(:rule_group)
    @rule_group_2 = FactoryBot.create(:rule_group)
    @rule_1 = FactoryBot.create(:rule)
    @rule_2 = FactoryBot.create(:rule)
  end

  test 'a rule group can be a parent for more than one rule' do
    rgr1 = FactoryBot.create(:rule_group_rule)
    rgr2 = FactoryBot.create(:rule_group_rule)
    assert_nothing_raised do
      rgr2.update!(rule_group: rgr1.rule_group)
    end
    assert_equal rgr1.rule_group, rgr2.rule_group
  end
end
