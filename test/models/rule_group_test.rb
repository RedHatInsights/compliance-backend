# frozen_string_literal: true

require 'test_helper'

class RuleGroupTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:ref_id).scoped_to(:benchmark_id)
  should validate_presence_of :ref_id
  should validate_presence_of :title
  should validate_presence_of :description
  should validate_presence_of :benchmark_id

  should belong_to(:benchmark)

  setup do
    fake_report = file_fixture('xccdf_report.xml').read
    @op_benchmark = OpenscapParser::TestResultFile.new(fake_report).benchmark
    @op_rule_groups = @op_benchmark.groups

    account = FactoryBot.create(:account)
    @profile = FactoryBot.create(
      :profile,
      account: account
    )
    @rule_group = FactoryBot.create(:rule_group)
    @parent_rule_group = FactoryBot.create(:rule_group)
  end

  test 'creates rule_groups from openscap_parser RuleGroup object' do
    assert RuleGroup.from_openscap_parser(@op_rule_groups.first,
                                          benchmark_id: @profile.benchmark.id).save
  end

  test 'updates rule groups with parent to set ancestry' do
    assert_nil @rule_group.ancestry

    @rule_group.update!(parent_id: @parent_rule_group.id)

    assert_not_nil @rule_group.ancestry
    assert_equal @rule_group.parent_id, @parent_rule_group.id
  end

  test 'rules_with_relationships' do
    rule = FactoryBot.create(:rule)
    required_rule_group = FactoryBot.create(:rule_group)
    @rule_group.rules << rule

    requires = {}
    requires[rule] = required_rule_group

    expected = [{ 'rule' => rule, 'requires' => required_rule_group, 'conflicts' => nil }]

    assert_equal @rule_group.rules_with_relationships(requires, {}), expected
  end
end
