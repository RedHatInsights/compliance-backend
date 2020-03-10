# frozen_string_literal: true

require 'test_helper'

class ProfileTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:ref_id)
    .scoped_to(%i[account_id benchmark_id])
  should validate_presence_of :ref_id
  should validate_presence_of :name
  should belong_to(:business_objective).optional

  setup do
    profiles(:one).update!(rules: [rules(:one), rules(:two)],
                           hosts: [hosts(:one)], account: accounts(:one))
  end

  test 'host is not compliant there are no results for all rules' do
    assert_not profiles(:one).compliant?(hosts(:one))
  end

  test 'host is compliant if all rules are "pass" or "notapplicable"' do
    test_results(:one).update(host: hosts(:one), profile: profiles(:one))
    RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass',
                      test_result: test_results(:one))
    RuleResult.create(rule: rules(:two), host: hosts(:one),
                      test_result: test_results(:one), result: 'notapplicable')
    assert profiles(:one).compliant?(hosts(:one))
  end

  test 'host is not compliant if some rules are "fail" or "error"' do
    test_results(:one).update(host: hosts(:one), profile: profiles(:one))
    RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass',
                      test_result: test_results(:one))
    RuleResult.create(rule: rules(:two), host: hosts(:one),
                      test_result: test_results(:one), result: 'error')
    assert_not profiles(:one).compliant?(hosts(:one))

    RuleResult.find_by(rule: rules(:two), host: hosts(:one),
                       test_result: test_results(:one))
              .update(result: 'fail')
    assert_not profiles(:one).compliant?(hosts(:one))
  end

  test 'compliance score in terms of percentage' do
    test_results(:one).update(host: hosts(:one), profile: profiles(:one))
    RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass',
                      test_result: test_results(:one))
    RuleResult.create(rule: rules(:two), host: hosts(:one), result: 'fail',
                      test_result: test_results(:one))
    assert 0.5, profiles(:one).compliance_score(hosts(:one))
  end

  test 'score with non-blank hosts' do
    assert_equal 0.0, profiles(:one).score
  end

  test 'score returns at least one decimal' do
    test_results(:one).update(host: hosts(:one), profile: profiles(:one))
    RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass',
                      test_result: test_results(:one))
    profiles(:one).update(hosts: profiles(:one).hosts + [hosts(:two)],
                          account: accounts(:test))
    assert_equal 0.5, profiles(:one).score
  end

  context 'threshold' do
    setup do
      test_results(:one).update(host: hosts(:one), profile: profiles(:one))
      RuleResult.create(rule: rules(:one), host: hosts(:one), result: 'pass',
                        test_result: test_results(:one))
      RuleResult.create(rule: rules(:two), host: hosts(:one),
                        test_result: test_results(:one), result: 'fail')
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

  context 'cloning profile to account' do
    should 'create host relation when the profile is created' do
      assert_difference('ProfileHost.count', 1) do
        cloned_profile = profiles(:one).clone_to(
          account: accounts(:one), host: hosts(:two)
        )
        assert hosts(:one).profiles.include?(cloned_profile)
      end
    end

    should 'create host relation even if profile is already created' do
      assert_difference('ProfileHost.count', 1) do
        cloned_profile = profiles(:two).clone_to(
          account: accounts(:one), host: hosts(:one)
        )
        assert hosts(:one).profiles.include?(cloned_profile)
      end
    end

    should 'not create host relation if host is already in profile' do
      assert_difference('ProfileHost.count', 0) do
        cloned_profile = profiles(:one).clone_to(
          account: accounts(:one), host: hosts(:one)
        )
        assert hosts(:one).profiles.include?(cloned_profile)
      end
    end
  end
end
