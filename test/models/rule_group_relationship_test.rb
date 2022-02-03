# frozen_string_literal: true

require 'test_helper'

class RuleGroupRelationshipTest < ActiveSupport::TestCase
  should belong_to(:left)
  should belong_to(:right)

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

  test 'rule or rule group cannot require the same rule or rule group twice' do
    rgr1 = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_requires)
    rgr2 = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_requires)
    rgr2.update!(left: rgr1.left)
    exception = assert_raises(Exception) do
      rgr2.update!(right: rgr1.right)
    end
    assert_equal(exception.message, 'Validation failed: Left has already been taken')
  end

  test 'rule or rule group cannot conflict with the same rule or rule group twice' do
    rgr1 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_conflicts)
    rgr2 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_conflicts)
    rgr2.update!(left: rgr1.left)
    exception = assert_raises(Exception) do
      rgr2.update!(right: rgr1.right)
    end
    assert_equal(exception.message, 'Validation failed: Left has already been taken')
  end

  test 'rule or rule group can be required by more than one rule or rule group' do
    rgr1 = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_group_requires)
    rgr2 = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_group_requires)
    assert_nothing_raised do
      rgr2.update!(right: rgr1.right)
    end
  end

  test 'rule or rule group can be conflicting with more than one rule or rule group' do
    rgr1 = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_group_conflicts)
    rgr2 = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_group_conflicts)
    assert_nothing_raised do
      rgr2.update!(right: rgr1.right)
    end
  end

  test 'two left_id columns can have the same value but left_type must be different' do
    rule = FactoryBot.create(:rule)
    rule_group = FactoryBot.create(:rule_group)
    rule_group.update!(id: rule.id)
    rgr1 = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_group_conflicts)
    rgr2 = FactoryBot.create(:rule_group_relationship, :for_rule_group_and_rule_group_conflicts)
    rgr1.update!(left: rule)
    assert_nothing_raised do
      rgr2.update!(left: rule_group)
    end
    assert_equal rule.id, rule_group.id
  end
end
