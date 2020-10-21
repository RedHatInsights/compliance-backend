# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class ProfileTest < ActiveSupport::TestCase
  should have_many(:policy_hosts).through(:policy_object)
  should have_many(:hosts).through(:profile_hosts)
  should have_many(:assigned_hosts).through(:policy_hosts).source(:host)
  should belong_to(:policy_object).optional
  should validate_uniqueness_of(:ref_id)
    .scoped_to(%i[account_id benchmark_id external policy_id])
  should validate_presence_of :ref_id
  should validate_presence_of :name
  should belong_to(:business_objective).optional

  setup do
    profiles(:one).update!(rules: [rules(:one), rules(:two)],
                           hosts: [hosts(:one)], account: accounts(:one))
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

  test 'allows profiles with same ref_id in two policies' do
    profiles(:one).update!(policy_id: policies(:one).id)
    assert profiles(:one).policy_id

    dupe = profiles(:one).dup
    dupe.update!(policy_id: policies(:two).id)
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

  test 'business_objective comes from policy for external profiles' do
    (bm = benchmarks(:one).dup).update!(version: '0.1.47')
    bo = BusinessObjective.create!(title: 'bo')
    bo2 = BusinessObjective.create!(title: 'bo2')
    (external_profile = profiles(:one).dup).update!(benchmark: bm,
                                                    business_objective: bo,
                                                    external: true)
    profiles(:one).update!(business_objective: bo2)
    assert_equal external_profile.policy, profiles(:one)
    assert_equal bo2, external_profile.business_objective
  end

  test 'compliance_threshold comes from policy for external profiles' do
    (bm = benchmarks(:one).dup).update!(version: '0.1.47')
    (external_profile = profiles(:one).dup).update!(benchmark: bm,
                                                    compliance_threshold: 100,
                                                    external: true)
    profiles(:one).update!(compliance_threshold: 30)
    assert_equal external_profile.policy, profiles(:one)
    assert_equal 30, external_profile.compliance_threshold
  end

  test "destroying a profile also destroys its policy's profiles" do
    DestroyProfilesJob.clear
    (bm = benchmarks(:one).dup).update!(version: '0.1.47')
    (external_profile = profiles(:one).dup).update!(benchmark: bm,
                                                    external: true)
    assert_equal external_profile.policy, profiles(:one)
    assert_difference('Profile.count' => -1) do
      profiles(:one).destroy
    end
    assert_equal 1, DestroyProfilesJob.jobs.size
    assert_equal [external_profile.id],
                 DestroyProfilesJob.jobs.dig(0, 'args', 0)
    assert_difference('Profile.count' => -1) do
      DestroyProfilesJob.drain
    end
  end

  test 'destroying a profile also destroys its related test results' do
    test_results(:one).update profile: profiles(:one), host: hosts(:one)
    assert_difference('Profile.count' => -1, 'TestResult.count' => -1) do
      profiles(:one).destroy
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

  test 'canonical is searchable' do
    assert profiles(:one).canonical?
    assert_includes Profile.search_for('canonical = true'), profiles(:one)
    assert_not_includes Profile.search_for('canonical = false'), profiles(:one)
  end

  test 'external is searchable' do
    profiles(:one).update!(external: true)
    assert profiles(:one).external
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

  context 'update_hosts' do
    should 'add new hosts to an empty host set' do
      profiles(:one).update!(hosts: [])
      assert_empty(profiles(:one).hosts)
      assert_difference('profiles(:one).hosts.count', hosts.count) do
        profiles(:one).update_hosts(hosts.pluck(:id))
      end
    end

    should 'add new hosts to an existing host set' do
      profiles(:one).update!(hosts: hosts[0...-1])
      assert_not_empty(profiles(:one).hosts)
      assert_difference('profiles(:one).hosts.count', 1) do
        profiles(:one).update_hosts(hosts.pluck(:id))
      end
    end

    should 'remove old hosts from an existing host set' do
      profiles(:one).update!(hosts: hosts)
      assert_equal hosts.count, profiles(:one).hosts.count
      assert_difference('profiles(:one).reload.hosts.count', -hosts.count) do
        profiles(:one).update_hosts([])
      end
    end

    should 'add new and remove old hosts from an existing host set' do
      profiles(:one).update!(host_ids: hosts.pluck(:id)[0...-1])
      assert_not_empty(profiles(:one).hosts)
      assert_difference('profiles(:one).hosts.count', 0) do
        profiles(:one).update_hosts(hosts.pluck(:id)[1..-1])
      end
    end
  end

  context 'update_rules' do
    should 'add new rules to an empty rule set' do
      profiles(:one).update!(rules: [])
      assert_empty(profiles(:one).rules)
      assert_difference(
        'profiles(:one).rules.count', profiles(:one).benchmark.rules.count
      ) do
        profiles(:one).update_rules(
          ids: profiles(:one).benchmark.rules.pluck(:id)
        )
      end
    end

    should 'add new rules to an existing rule set' do
      profiles(:one).update!(rules: profiles(:one).rules[0...-1])
      assert_not_empty(profiles(:one).rules)
      assert_difference('profiles(:one).rules.count', 1) do
        profiles(:one).update_rules(
          ids: profiles(:one).benchmark.rules.pluck(:id)
        )
      end
    end

    should 'remove old rules from an existing rule set' do
      assert_not_empty(profiles(:one).rules)
      assert_difference('profiles(:one).rules.count',
                        -profiles(:one).rules.count) do
        profiles(:one).update_rules(
          ids: []
        )
      end
    end

    should 'add new and remove old rules from an existing rule set' do
      original_rule_ids = profiles(:one).rules.pluck(:id)
      profiles(:one).update!(rule_ids: original_rule_ids[0...-1])
      assert_not_empty(profiles(:one).rules)
      assert_difference('profiles(:one).rules.count', 0) do
        profiles(:one).update_rules(
          ids: original_rule_ids[1..-1]
        )
      end
    end
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

    should 'clone profiles as external by default' do
      profiles(:one).update!(account: nil, hosts: [])
      assert_difference('ProfileHost.count' => 1, 'Profile.count' => 1) do
        cloned_profile = profiles(:one).clone_to(
          account: accounts(:one), host: hosts(:one)
        )
        assert hosts(:one).profiles.include?(cloned_profile)
        assert cloned_profile.external
      end
    end

    should 'clone profiles as internal if specified' do
      profiles(:one).update!(account: nil, hosts: [])
      assert_difference('ProfileHost.count' => 1, 'Profile.count' => 1) do
        cloned_profile = profiles(:one).clone_to(
          account: accounts(:one), host: hosts(:one), external: false
        )
        assert hosts(:one).profiles.include?(cloned_profile)
        assert_not cloned_profile.external
      end
    end

    should 'not add rules to existing profiles' do
      assert_not_empty(profiles(:one).rules)
      profiles(:one).update!(account: nil, hosts: [])
      existing_profile = profiles(:one).clone_to(account: accounts(:one),
                                                 host: hosts(:one))
      existing_profile.update!(rules: [])
      assert_difference('ProfileHost.count' => 0,
                        'Profile.count' => 0,
                        'ProfileRule.count' => 0) do
        cloned_profile = profiles(:one).clone_to(
          account: accounts(:one), host: hosts(:one)
        )
        assert hosts(:one).profiles.include?(cloned_profile)
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
