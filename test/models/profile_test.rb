# frozen_string_literal: true

require 'test_helper'

class ProfileTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:ref_id).scoped_to(:account_id)
  should validate_presence_of :ref_id
  should validate_presence_of :name

  setup do
    hosts(:one).profiles << profiles(:one)
    profiles(:one).update(rules: [rules(:one), rules(:two)])
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
end
