# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class ProfileTest < ActiveSupport::TestCase
  should have_many(:policy_hosts).through(:policy)
  should have_many(:assigned_hosts).through(:policy_hosts).source(:host)
  should have_many(:hosts).through(:test_results)
  should have_many(:test_results).dependent(:destroy)
  should have_many(:rule_results).through(:test_results)
  should belong_to(:policy).optional
  should validate_uniqueness_of(:ref_id)
    .scoped_to(%i[account_id benchmark_id external policy_id])
  should validate_presence_of :ref_id
  should validate_presence_of :name

  setup do
    policies(:one).update!(hosts: [hosts(:one)], account: accounts(:one))
    profiles(:one).update!(rules: [rules(:one), rules(:two)],
                           account: accounts(:one))
  end

  test 'uniqness by external without a policy' do
    orig = profiles(:one)
    assert_nil orig.policy_id

    (dupe = orig.dup).update!(external: !orig.external)
    assert_nil dupe.policy_id
    assert dupe.external != orig.external

    assert_raises ActiveRecord::RecordInvalid do
      orig.dup.save!
    end
  end

  test 'unqiness by ref_id for an internal profile' do
    profiles(:one).update!(external: false)

    assert_raises ActiveRecord::RecordInvalid do
      profiles(:one).dup.update!(policy_id: policies(:one).id)
    end
  end

  test 'uniqness by ref_id in a policy, the same external boolean value' do
    profiles(:one).update!(policy_id: policies(:one).id)
    assert profiles(:one).policy_id

    assert_raises ActiveRecord::RecordInvalid do
      profiles(:one).dup.save!
    end
  end

  test 'uniqness by ref_id in a policy, different external boolean value' do
    profiles(:one).update!(policy_id: policies(:one).id)
    assert profiles(:one).policy_id

    assert_raises ActiveRecord::RecordInvalid do
      profiles(:one).dup.update!(external: !profiles(:one).external)
    end
  end

  test 'uniqness of policy profiles by policy type' do
    (bm = benchmarks(:one).dup).update!(version: '123')
    profiles(:one).update!(policy_id: policies(:one).id,
                           parent_profile: profiles(:two))
    assert profiles(:one).policy_id
    assert_not profiles(:one).external

    p = profiles(:one).dup
    assert_not p.update(policy_id: policies(:two).id, benchmark: bm)
    assert p.errors.full_messages.join['Policy type must be unique']
  end

  test 'absence of a policy, but policy_id set' do
    assert_nothing_raised do
      profiles(:one).update!(policy_id: policies(:one).id)
    end

    assert_not profiles(:one).update(policy_id: UUID.generate)
    assert_includes profiles(:one).errors[:policy], "can't be blank"
  end

  test 'coexistence of external profiles with and without a policy' do
    dupe1 = profiles(:one).dup
    dupe1.update!(external: true, policy_id: policies(:one).id)
    assert dupe1.policy_id

    profiles(:one).update!(external: true)
    assert_not profiles(:one).policy_id
    assert profiles(:one).external

    dupe2 = profiles(:one).dup
    dupe2.update!(external: true, policy_id: policies(:two).id)
    assert dupe2.policy_id
  end

  test 'allows external profiles with same ref_id in two policies' do
    profiles(:one).update!(external: true, policy_id: policies(:one).id)
    assert profiles(:one).policy_id

    dupe = profiles(:one).dup
    dupe.update!(policy_id: policies(:two).id)
    assert dupe.policy_id
  end

  test 'policy_profile finds the initial profile of a policy' do
    profiles(:two).update!(account: accounts(:test), policy: nil)
    assert_nil profiles(:two).policy_profile
    profiles(:one).update!(policy: policies(:one), external: false)
    assert_equal profiles(:one), profiles(:one).policy_profile
    profiles(:two).update!(policy: policies(:one), external: true)
    assert_equal profiles(:one), profiles(:one).policy_profile
    assert_equal profiles(:one), profiles(:two).policy_profile
  end

  test 'creation of internal profile with a policy, external profile exists' do
    profiles(:one).update!(external: true)
    dupe = profiles(:one).dup
    dupe.update!(external: false, policy_id: policies(:one).id)
    assert dupe.policy_id
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
      profiles(:one).update!(policy_id: policies(:one).id)
      assert_equal policies(:one), profiles(:one).policy
    end

    should 'host is compliant if 50% of rules pass with a threshold of 50' do
      policies(:one).update(compliance_threshold: 50)
      assert profiles(:one).reload.compliant?(hosts(:one))
    end

    should 'host is not compliant if 50% rules pass with a threshold of 51' do
      policies(:one).update(compliance_threshold: 51)
      assert_not profiles(:one).reload.compliant?(hosts(:one))
    end

    should 'host is compliant if it is compliant on some policy profile' do
      profiles(:two).update!(policy: policies(:one),
                             account: accounts(:one))
      policies(:one).update(compliance_threshold: 50)
      assert policies(:one).compliant?(hosts(:one))
      assert profiles(:two).reload.compliant?(hosts(:one))
    end
  end

  test 'orphaned business objectives' do
    profiles(:one).update!(policy_id: policies(:one).id)
    bo = BusinessObjective.new(title: 'abcd')
    bo.save
    policies(:one).update(business_objective: bo)
    assert profiles(:one).reload.business_objective, bo
    policies(:one).update(business_objective: nil)
    assert_empty BusinessObjective.where(title: 'abcd')
  end

  test 'business_objective comes from policy' do
    policies(:one).update!(business_objective: business_objectives(:one))
    profiles(:one).update!(policy: nil)
    assert_nil profiles(:one).business_objective
    profiles(:one).update!(policy: policies(:one))
    assert_equal business_objectives(:one), profiles(:one).business_objective
  end

  test 'compliance_threshold comes from policy default for external profiles' do
    (bm = benchmarks(:one).dup).update!(version: '0.1.47')
    (external_profile = profiles(:one).dup).update!(benchmark: bm,
                                                    policy: nil)
    assert_nil external_profile.policy
    assert_equal 100, external_profile.compliance_threshold
  end

  context 'destroying' do
    setup do
      profiles(:one).update!(policy_id: policies(:one).id)
    end

    should 'also destroys its policy if empty' do
      assert_difference('Profile.count' => -1, 'Policy.count' => -1) do
        profiles(:one).destroy
      end
    end

    should 'also destroys its policy having more profiles' do
      profiles(:two).update!(account: accounts(:one),
                             external: true,
                             policy_id: policies(:one).id)

      assert_difference('Profile.count' => -2, 'Policy.count' => -1) do
        profiles(:one).destroy
      end
    end

    should 'also destroys its related test results' do
      assert_equal 1, profiles(:one).test_results.count
      assert_difference('Profile.count' => -1, 'TestResult.count' => -1) do
        profiles(:one).destroy
      end
    end

    should 'also destroys its related rule results' do
      assert_equal 1, profiles(:one).rule_results.count
      assert_difference('Profile.count' => -1, 'RuleResult.count' => -1) do
        profiles(:one).destroy
      end
    end
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

  context 'in_policy scope' do
    setup do
      profiles(:one).update!(policy: policies(:one),
                             account: accounts(:one))
    end

    should 'find by exact profile id' do
      profiles(:two).update!(policy: nil,
                             account: accounts(:one))
      assert_includes Profile.in_policy(profiles(:two).id),
                      profiles(:two)
      assert_equal 1, Profile.in_policy(profiles(:two).id).length
    end

    should 'find all policy profiles with policy id provided' do
      profiles(:two).update!(policy: policies(:one),
                             external: true,
                             account: accounts(:one))

      profiles(:two).dup.update!(policy: policies(:two),
                                 account: accounts(:one))

      returned_profiles = Profile.in_policy(policies(:one).id)
      assert_includes returned_profiles, profiles(:one)
      assert_includes returned_profiles, profiles(:two)
      assert_equal 2, returned_profiles.length
    end

    should 'find all policy profiles with any policy profile id provided' do
      # set different UUIDs on profiles, as they share
      # the same labels/uuids with policies.
      profiles(:one).update!(id: SecureRandom.uuid)
      profiles(:two).update!(id: SecureRandom.uuid,
                             policy: policies(:one),
                             external: true,
                             account: accounts(:one))

      profiles(:two).dup.update!(policy: policies(:two).dup,
                                 account: accounts(:one))

      returned_profiles = Profile.in_policy(profiles(:two).id)
      assert_includes returned_profiles, profiles(:one)
      assert_includes returned_profiles, profiles(:two)
      assert_equal 2, returned_profiles.length
    end

    should 'find nothing on invalid UUID' do
      assert_equal Profile.none, Profile.in_policy('bogus')
    end
  end

  test 'has_test_results filters by test results available' do
    test_results(:one).update profile: profiles(:one), host: hosts(:one)
    profiles(:two).test_results.destroy_all
    assert profiles(:one).test_results.present?
    assert profiles(:two).test_results.empty?
    assert_includes(Profile.search_for('has_test_results = true'),
                    profiles(:one))
    assert_not_includes(Profile.search_for('has_test_results = true'),
                        profiles(:two))
    assert_includes(Profile.search_for('has_test_results = false'),
                    profiles(:two))
    assert_not_includes(Profile.search_for('has_test_results = false'),
                        profiles(:one))
  end

  context 'policy_test_results' do
    should 'return all test results on the policy' do
      profiles(:one).update!(policy: policies(:one))
      profiles(:two).update!(policy: policies(:one),
                             account: accounts(:one))

      assert_not_empty policies(:one).test_results
      assert_equal policies(:one).test_results,
                   profiles(:one).policy_test_results
      assert_equal policies(:one).test_results,
                   profiles(:two).policy_test_results
    end
  end

  context 'policy_test_result_hosts' do
    should 'return all test result hosts on the policy' do
      profiles(:one).update!(policy: policies(:one))
      profiles(:two).update!(policy: policies(:one),
                             account: accounts(:one))

      assert_not_empty policies(:one).test_result_hosts
      assert_equal Set.new(policies(:one).test_result_hosts),
                   Set.new(profiles(:one).policy_test_result_hosts)
      assert_equal Set.new(policies(:one).test_result_hosts),
                   Set.new(profiles(:two).policy_test_result_hosts)
    end
  end

  context 'has_policy_test_results filter' do
    setup do
      test_results(:one).update(profile: profiles(:one), host: hosts(:one))
      profiles(:two).test_results.destroy_all
    end

    should 'find a policy profile if it has a test result' do
      profiles(:one).update!(policy: policies(:one))
      assert profiles(:one).test_results.present?
      assert profiles(:two).test_results.empty?

      assert_includes(Profile.search_for('has_policy_test_results = true'),
                      profiles(:one))
      assert_not_includes(Profile.search_for('has_policy_test_results = true'),
                          profiles(:two))
      assert_includes(Profile.search_for('has_policy_test_results = false'),
                      profiles(:two))
      assert_not_includes(Profile.search_for('has_policy_test_results = false'),
                          profiles(:one))
    end

    should 'find a policy profile if it has a test result on a scope change' do
      profiles(:one).update!(policy: policies(:one))
      profiles(:two).update!(account: accounts(:one))

      assert profiles(:one).test_results.present?
      assert profiles(:two).test_results.empty?

      Profile.where(account: accounts(:one)).scoping do
        assert_includes(Profile.search_for('has_policy_test_results = true'),
                        profiles(:one))
        assert_not_includes(
          Profile.search_for('has_policy_test_results = true'),
          profiles(:two)
        )
        assert_includes(Profile.search_for('has_policy_test_results = false'),
                        profiles(:two))
        assert_not_includes(
          Profile.search_for('has_policy_test_results = false'),
          profiles(:one)
        )
      end
    end

    should 'find all policy profiles if one has a test result' do
      profiles(:one).update!(policy: policies(:one),
                             external: true)
      profiles(:two).update!(policy: policies(:one),
                             external: false)

      assert profiles(:one).test_results.present?
      assert profiles(:two).test_results.empty?
      assert_includes(Profile.search_for('has_policy_test_results = true'),
                      profiles(:two))
      assert_not_includes(Profile.search_for('has_policy_test_results = false'),
                          profiles(:two))
      assert_includes(Profile.search_for('has_policy_test_results = true'),
                      profiles(:one))
      assert_not_includes(Profile.search_for('has_policy_test_results = false'),
                          profiles(:one))
    end
  end

  test 'canonical is searchable' do
    assert profiles(:one).canonical?
    assert_includes Profile.search_for('canonical = true'), profiles(:one)
    assert_not_includes Profile.search_for('canonical = false'), profiles(:one)
  end

  test 'external is searchable' do
    profiles(:one).update!(policy: nil, external: true)
    assert_nil profiles(:one).policy
    assert_includes Profile.search_for('external = true'), profiles(:one)
    assert_includes Profile.external, profiles(:one)
    assert_not_includes Profile.search_for('external = false'), profiles(:one)
    assert_not_includes Profile.external(false), profiles(:one)
  end

  test 'os_major_version scope' do
    bm61 = Xccdf::Benchmark.create!(
      ref_id: 'foo_bar.ssgproject.benchmark_RHEL-6',
      version: '1', title: 'A', description: 'A'
    )
    bm62 = Xccdf::Benchmark.create!(
      ref_id: 'foo_bar.ssgproject.benchmark_RHEL-6',
      version: '2', title: 'A', description: 'A'
    )
    bm8 = Xccdf::Benchmark.create!(
      ref_id: 'foo_bar.ssgproject.benchmark_RHEL-8',
      version: '1', title: 'A', description: 'A'
    )
    p61a = Profile.create!(benchmark: bm61, ref_id: 'A', name: 'A')
    p61b = Profile.create!(benchmark: bm61, ref_id: 'B', name: 'B')
    p62 = Profile.create!(benchmark: bm62, ref_id: 'A', name: 'A')
    p8 = Profile.create!(benchmark: bm8, ref_id: 'A', name: 'A')
    assert_equal Set.new(Profile.os_major_version(6).to_a),
                 Set.new([p61a, p61b, p62])
    assert_equal Set.new(Profile.os_major_version(7).to_a), Set.new(profiles)
    assert_equal Profile.os_major_version(8).to_a, [p8]

    assert_equal Set.new(Profile.os_major_version(8, false).to_a),
                 Set.new(Profile.where.not(id: p8.id).to_a)
    assert_equal Set.new(Profile.os_major_version(6, false).to_a),
                 Set.new([p8] + profiles)
  end

  test 'os_major_version scoped_search' do
    bm61 = Xccdf::Benchmark.create!(
      ref_id: 'foo_bar.ssgproject.benchmark_RHEL-6',
      version: '1', title: 'A', description: 'A'
    )
    bm62 = Xccdf::Benchmark.create!(
      ref_id: 'foo_bar.ssgproject.benchmark_RHEL-6',
      version: '2', title: 'A', description: 'A'
    )
    bm8 = Xccdf::Benchmark.create!(
      ref_id: 'foo_bar.ssgproject.benchmark_RHEL-8',
      version: '1', title: 'A', description: 'A'
    )
    p61a = Profile.create!(benchmark: bm61, ref_id: 'A', name: 'A')
    p61b = Profile.create!(benchmark: bm61, ref_id: 'B', name: 'B')
    p62 = Profile.create!(benchmark: bm62, ref_id: 'A', name: 'A')
    p8 = Profile.create!(benchmark: bm8, ref_id: 'A', name: 'A')
    assert_equal Set.new(Profile.search_for('os_major_version = 6').to_a),
                 Set.new([p61a, p61b, p62])
    assert_equal Set.new(Profile.search_for('os_major_version = 7').to_a),
                 Set.new(profiles)
    assert_equal Profile.search_for('os_major_version = 8').to_a, [p8]

    assert_equal Set.new(Profile.search_for('os_major_version != 8').to_a),
                 Set.new(Profile.where.not(id: p8.id).to_a)
    assert_equal Set.new(Profile.search_for('os_major_version != 6').to_a),
                 Set.new([p8] + profiles)
  end

  context '#ssg_versions' do
    setup do
      profiles(:one).benchmark.update!(version: '0.1.234')
    end

    should 'scope should allow single values' do
      assert_includes Profile.ssg_versions('0.1.234'), profiles(:one)
      assert_includes Profile.search_for('ssg_version=0.1.234'), profiles(:one)
    end

    should 'scoped_search should allow single values' do
      assert_includes Profile.search_for('ssg_version = 0.1.234'),
                      profiles(:one)
      assert_not_includes Profile.search_for('ssg_version != 0.1.234'),
                          profiles(:one)
    end

    should 'scope should allow multiple values' do
      assert_includes Profile.ssg_versions(['0.1.234', 'foo']), profiles(:one)
      assert_not_includes Profile.ssg_versions(['foo']), profiles(:one)
    end
  end

  test 'short_ref_id' do
    profile1 = profiles(:one)
    profile1.update!(ref_id: 'xccdf_org.ssgproject.content_profile_one')
    assert_equal profile1.short_ref_id, 'one'

    profile2 = profiles(:two)
    assert_equal profile2.short_ref_id, 'xccdf_org.ssgproject.profile2'
  end

  context 'fill_from_parent' do
    NAME = 'Customized profile'
    DESCRIPTION = 'The best profile ever'

    should 'copy attributes from the parent profile' do
      profile = Profile.new(
        parent_profile_id: profiles(:one).id, account_id: accounts(:one).id
      ).fill_from_parent

      assert_equal profiles(:one).ref_id, profile.ref_id
      assert_equal profiles(:one).name, profile.name
      assert_equal profiles(:one).description, profile.description
      assert_equal profiles(:one).benchmark_id, profile.benchmark_id
      assert_not profile.external
    end

    should 'allow some customized attributes' do
      profile = Profile.new(name: NAME,
                            description: DESCRIPTION,
                            ref_id: 'this should be a noop',
                            benchmark_id: 'this should be a noop',
                            parent_profile_id: profiles(:one).id)
                       .fill_from_parent

      assert_equal profiles(:one).ref_id, profile.ref_id
      assert_equal NAME, profile.name
      assert_equal DESCRIPTION, profile.description
      assert_equal profiles(:one).benchmark_id, profile.benchmark_id
      assert_not profile.external
    end
  end

  context 'update_rules' do
    should 'add new rules to an empty rule set' do
      profiles(:one).update!(rules: [])
      assert_empty(profiles(:one).rules)
      benchmark_rules_count = profiles(:one).benchmark.rules.count
      assert_difference(
        'profiles(:one).rules.count', benchmark_rules_count
      ) do
        changes = profiles(:one).update_rules(
          ids: profiles(:one).benchmark.rules.pluck(:id)
        )
        assert_equal [benchmark_rules_count, 0], changes
      end
    end

    should 'add new rules to an existing rule set' do
      profiles(:one).update!(rules: profiles(:one).rules[0...-1])
      assert_not_empty(profiles(:one).rules)
      assert_difference('profiles(:one).rules.count', 1) do
        changes = profiles(:one).update_rules(
          ids: profiles(:one).benchmark.rules.pluck(:id)
        )
        assert_equal [1, 0], changes
      end
    end

    should 'remove old rules from an existing rule set' do
      assert_not_empty(profiles(:one).rules)
      rules_count = profiles(:one).rules.count
      assert_difference('profiles(:one).rules.count', -rules_count) do
        changes = profiles(:one).update_rules(
          ids: []
        )
        assert_equal [0, rules_count], changes
      end
    end

    should 'add new and remove old rules from an existing rule set' do
      original_rule_ids = profiles(:one).rules.pluck(:id)
      profiles(:one).update!(rule_ids: original_rule_ids[0...-1])
      assert_not_empty(profiles(:one).rules)
      assert_difference('profiles(:one).rules.count', 0) do
        changes = profiles(:one).update_rules(
          ids: original_rule_ids[1..-1]
        )
        assert_equal [1, 1], changes
      end
    end
  end

  context 'cloning profile to account' do
    setup do
      PolicyHost.destroy_all
      profiles(:one).update!(policy_id: policies(:one).id)
    end

    should 'use the same profile when the host is assinged' do
      policy = profiles(:one).policy
      policy.hosts << hosts(:two)

      dupe = profiles(:one).dup
      dupe.assign_attributes(external: true)

      assert_difference('Profile.count' => 0, 'Policy.count' => 0,
                        'PolicyHost.count' => 0) do
        cloned_profile = dupe.clone_to(
          account: accounts(:one),
          policy: Policy.with_hosts(hosts(:two))
                        .find_by(account: accounts(:one))
        )

        assert_equal cloned_profile.reload.policy_id, policies(:one).id
        assert_includes policy.reload.profiles, profiles(:one)
      end
    end

    should 'assign different SSG profile to a policy the host is part of' do
      policy = profiles(:one).policy
      policy.hosts << hosts(:two)

      second_benchmark = benchmarks(:one).dup
      second_benchmark.update!(version: '0.0.7')

      dupe = profiles(:one).dup
      dupe.update!(account: nil, benchmark: second_benchmark)

      assert_difference('Profile.count' => 1, 'Policy.count' => 0,
                        'PolicyHost.count' => 0) do
        cloned_profile = dupe.clone_to(
          account: accounts(:one),
          policy: Policy.with_hosts(hosts(:two))
                        .find_by(account: accounts(:one))
        )

        assert_equal cloned_profile.reload.policy_id, policies(:one).id
        assert_includes policy.reload.profiles, cloned_profile
      end
    end

    should 'set the parent profile ID to the original profile' do
      assert profiles(:one).canonical?
      assert_difference('Profile.count', 1) do
        cloned_profile = profiles(:one).clone_to(
          account: accounts(:test),
          policy: Policy.with_hosts(hosts(:one))
                        .find_by(account: accounts(:test))
        )

        assert_equal profiles(:one), cloned_profile.parent_profile
      end
    end

    should 'clone profiles as external by default' do
      profiles(:one).update!(account: nil, hosts: [])
      assert_difference('PolicyHost.count' => 0, 'Profile.count' => 1) do
        cloned_profile = profiles(:one).clone_to(
          account: accounts(:one),
          policy: Policy.with_hosts(hosts(:one))
                        .find_by(account: accounts(:one))
        )
        assert_not hosts(:one).assigned_profiles.include?(cloned_profile)
        assert_nil cloned_profile.policy
      end
    end

    should 'not add rules to existing profiles' do
      assert_not_empty(profiles(:one).rules)
      profiles(:one).update!(account: nil, hosts: [])
      existing_profile = profiles(:one).clone_to(
        account: accounts(:one),
        policy: Policy.with_hosts(hosts(:one)).find_by(account: accounts(:one))
      )
      existing_profile.update!(rules: [])
      assert_difference('PolicyHost.count' => 0,
                        'Profile.count' => 0,
                        'ProfileRule.count' => 0) do
        cloned_profile = profiles(:one).clone_to(
          account: accounts(:one),
          policy: Policy.with_hosts(hosts(:one))
                        .find_by(account: accounts(:one))
        )
        assert_not hosts(:one).assigned_profiles.include?(cloned_profile)
      end
      assert_empty(existing_profile.rules)
    end
  end

  context 'profile tailoring' do
    setup do
      @parent_profile = Profile.create!(benchmark: benchmarks(:one),
                                        ref_id: 'foo',
                                        name: 'foo profile')
      @parent_profile.update! rules: [rules(:one)]
      @profile = @parent_profile.clone_to(
        account: accounts(:one),
        policy: Policy.with_hosts(hosts(:one)).find_by(account: accounts(:one))
      )
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
