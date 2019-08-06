# frozen_string_literal: true

require 'test_helper'

class ProfileTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:ref_id).scoped_to(%i[account_id name])
  should validate_presence_of :ref_id
  should validate_presence_of :name
  should belong_to(:business_objective).optional

  setup do
    hosts(:one).profiles << profiles(:one)
    profiles(:one).update(rules: [rules(:one), rules(:two)])
    profiles(:one).stubs(:hosts).returns([hosts(:one)])
  end

  test 'host is not compliant there are no results for all rules' do
    assert_not profiles(:one).compliant?(hosts(:one))
  end

  test 'host is compliant if all rules are "pass" or "notapplicable"' do
    RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass')
    RuleResult.create(rule: rules(:two), host: hosts(:one),
                      result: 'notapplicable')
    assert profiles(:one).compliant?(hosts(:one))
  end

  test 'host is not compliant if some rules are "fail" or "notselected"' do
    RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass')
    RuleResult.create(rule: rules(:two), host: hosts(:one),
                      result: 'notchecked')
    assert_not profiles(:one).compliant?(hosts(:one))

    RuleResult.find_by(rule: rules(:two), host: hosts(:one))
              .update(result: 'fail')
    assert_not profiles(:one).compliant?(hosts(:one))
  end

  test 'compliance score in terms of percentage' do
    RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass')
    RuleResult.create(rule: rules(:two), host: hosts(:one), result: 'fail')
    assert 0.5, profiles(:one).compliance_score(hosts(:one))
  end

  test 'score with non-blank hosts' do
    assert_equal 0.0, profiles(:one).score
  end

  test 'score returns at least one decimal' do
    RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass')
    profiles(:one).hosts << hosts(:two)
    assert_equal 0.5, profiles(:one).score
  end

  context 'threshold' do
    setup do
      RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass')
      RuleResult.create(rule: rules(:two), host: hosts(:one),
                        result: 'notchecked')
    end

    should 'host is compliant if 50% of rules pass with a threshold of 50' do
      profiles(:one).update(compliance_threshold: 50)
      assert profiles(:one).compliant?(hosts(:one))
    end

    should 'host is not compliant if 50% rules pass with a threshold of 51' do
      profiles(:one).update(compliance_threshold: 51)
      assert_not profiles(:one).compliant?(hosts(:one))
    end
  end

  test 'orphaned business objectives' do
    bo = BusinessObjective.new(title: 'abcd')
    bo.save
    profiles(:one).update(business_objective: bo)
    assert profiles(:one).business_objective, bo
    profiles(:one).update(business_objective: nil)
    assert_empty BusinessObjective.where(title: 'abcd')
  end
end
