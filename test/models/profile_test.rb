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

  test 'score with non-blank test results' do
    test_results(:one).update!(profile: profiles(:one), host: hosts(:one),
                               score: 0.5, end_time: DateTime.now)
    test_results(:two).update!(profile: profiles(:one), host: hosts(:two),
                               score: 0.2, end_time: DateTime.now)
    assert_equal 0.35, profiles(:one).score
  end

  test 'score returns at least one decimal' do
    test_results(:one).update!(profile: profiles(:one), host: hosts(:one),
                               score: 1, end_time: DateTime.now)
    test_results(:two).update!(profile: profiles(:one), host: hosts(:two),
                               score: 0, end_time: DateTime.now)
    assert_equal 0.5, profiles(:one).score
  end

  context 'threshold' do
    setup do
      test_results(:one).update(host: hosts(:one), profile: profiles(:one),
                                score: 50)
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

  test 'canonical profiles have no parent_profile_id' do
    assert Profile.new.canonical?, 'nil parent_profile_id should be canonical'
  end

  test 'non-canonical profiles have a parent_profile_id' do
    assert_not Profile.new(
      parent_profile_id: profiles(:one).id
    ).canonical?, 'non-nil parent_profile_id should not be canonical'
  end

  test 'canonical scope finds only canonical profiles' do
    p1 = Profile.create!(ref_id: 'p1_foo_ref_id',
                         name: 'p1 foo',
                         benchmark_id: benchmarks(:one).id,
                         parent_profile_id: profiles(:one).id)
    p2 = Profile.create!(ref_id: 'p2_foo_ref_id',
                         name: 'p2 foo',
                         benchmark_id: benchmarks(:one).id)
    assert_includes Profile.canonical, p2
    assert_not_includes Profile.canonical, p1
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

    should 'set the parent profile ID to the original profile' do
      canonical = Profile.canonical.first

      assert_difference('Profile.count', 1) do
        cloned_profile = canonical.clone_to(
          account: accounts(:one), host: hosts(:one)
        )

        assert_equal canonical, cloned_profile.parent_profile
      end
    end
  end

  context 'profile tailoring' do
    setup do
      @parent_profile = Profile.create!(benchmark: benchmarks(:one),
                                        ref_id: 'foo',
                                        name: 'foo profile')
      @parent_profile.update! rules: [rules(:one)]
      @profile = @parent_profile.clone_to(account: accounts(:one),
                                          host: hosts(:one))
      @profile.update! rules: [rules(:two)]
    end

    should 'send the correct rule ref ids to the tailoring file service' do
      assert_equal({ rules(:one).ref_id => false, rules(:two).ref_id => true },
                   @profile.tailored_rule_ref_ids)
    end

    should 'properly detects added_rules' do
      assert_equal [rules(:two)], @profile.added_rules
    end

    should 'properly detects removed_rules' do
      assert_equal [rules(:one)], @profile.removed_rules
    end
  end
end
