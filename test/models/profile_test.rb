# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class ProfileTest < ActiveSupport::TestCase
  context 'model' do
    setup { FactoryBot.create(:canonical_profile) }

    should validate_presence_of :ref_id
    should validate_uniqueness_of(:ref_id)
      .scoped_to(%i[account_id benchmark_id os_minor_version policy_id])
      .with_message('must be unique in a policy OS version')
  end

  should have_many(:policy_hosts).through(:policy)
  should have_many(:assigned_hosts).through(:policy_hosts).source(:host)
  should have_many(:hosts).through(:test_results)
  should have_many(:test_results).dependent(:destroy)
  should have_many(:rule_results).through(:test_results)
  should belong_to(:policy).optional
  should validate_presence_of :name

  setup do
    @account = FactoryBot.create(:account)
    @host = FactoryBot.create(:host, org_id: @account.org_id)
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    @policy = FactoryBot.create(:policy, account: @account, hosts: [@host])
  end

  test 'unqiness by ref_id for an internal profile' do
    profile = FactoryBot.create(:profile, account: @account)

    assert_raises ActiveRecord::RecordInvalid do
      profile.dup.update!(policy_id: @policy.id)
    end
  end

  test 'uniqness by ref_id in a policy, the same external boolean value' do
    profile = FactoryBot.create(:profile, policy: @policy, account: @account)
    assert profile.policy_id

    assert_raises ActiveRecord::RecordInvalid do
      profile.dup.save!
    end
  end

  test 'uniqness by ref_id in a policy, different external boolean value' do
    profile = FactoryBot.create(:profile, policy: @policy, account: @account)
    assert profile.policy_id

    assert_raises ActiveRecord::RecordInvalid do
      profile.dup.update!(external: !profile.external)
    end
  end

  test 'uniqness of policy profiles by policy type' do
    profile = FactoryBot.create(:profile, account: @account, policy: @policy)

    (bm = profile.benchmark.dup).update!(version: '123')

    assert profile.policy_id
    assert_not profile.external

    policy = FactoryBot.create(:policy, account: @account)

    p = profile.dup
    assert_not p.update(policy_id: policy.id, benchmark: bm)
    assert p.errors.full_messages.join['Policy type must be unique']
  end

  test 'absence of a policy, but policy_id set' do
    profile = FactoryBot.create(:profile, account: @account)

    assert_not profile.update(policy_id: UUID.generate)
    assert_includes profile.errors[:policy], "can't be blank"
  end

  test 'coexistence of external profiles with and without a policy' do
    profile = FactoryBot.create(:profile, account: @account, policy: nil)
    policy = FactoryBot.create(:policy, account: @account)

    dupe1 = profile.dup
    dupe1.update!(external: true, policy_id: @policy.id)
    assert dupe1.policy_id

    profile.update!(external: true)
    assert_not profile.policy_id
    assert profile.external

    dupe2 = profile.dup
    dupe2.update!(external: true, policy_id: policy.id)
    assert dupe2.policy_id
  end

  test 'allows external profiles with same ref_id in two policies' do
    profile = FactoryBot.create(
      :profile,
      policy: @policy,
      account: @account,
      external: true
    )

    assert profile.policy_id

    dupe = profile.dup
    policy = FactoryBot.create(:policy, account: @account)
    dupe.update!(policy_id: policy.id)
    assert dupe.policy_id
  end

  test 'policy_profile finds the initial profile of a policy' do
    profile1 = FactoryBot.create(:profile, account: @account, policy: @policy)
    profile2 = FactoryBot.create(
      :profile,
      account: @account,
      parent_profile: profile1.parent_profile,
      policy: @policy,
      external: true
    )

    assert_equal profile1, profile1.policy_profile
    assert_equal profile1, profile2.policy_profile
  end

  test 'creation of internal profile with a policy, external profile exists' do
    profile = FactoryBot.create(:profile, account: @account, external: true)

    dupe = profile.dup
    dupe.update!(external: false, policy_id: @policy.id)
    assert dupe.policy_id
  end

  context 'compliance' do
    setup do
      @host = FactoryBot.create(:host, org_id: @account.org_id)
      @policy.hosts << @host
      @profile = FactoryBot.create(
        :profile,
        :with_rules,
        policy: @policy,
        account: @account
      )

      @tr = FactoryBot.create(:test_result, profile: @profile, host: @host)
    end

    should 'host not compliant if there are no results for all rules' do
      assert_not @profile.compliant?(@host)
    end

    should 'host not compliant if some rules are "fail" or "error"' do
      %w[pass error].each_with_index do |status, idx|
        FactoryBot.create(
          :rule_result,
          rule: @profile.rules[idx],
          test_result: @tr,
          host: @host,
          result: status
        )
      end

      assert_not @profile.compliant?(@host)
    end

    should 'compliance score in terms of percentage' do
      %w[pass error].each_with_index do |status, idx|
        FactoryBot.create(
          :rule_result,
          rule: @profile.rules[idx],
          test_result: @tr,
          host: @host,
          result: status
        )
      end
      assert 0.5, @profile.compliance_score(@host)
    end

    should 'score with non-blank test results' do
      @tr.update(score: 0.5)
      FactoryBot.create(
        :test_result,
        host: FactoryBot.create(:host, org_id: @account.org_id),
        profile: @profile,
        score: 0.2
      )
      assert_equal 0.35, @profile.score
    end

    should 'score returns at least one decimal' do
      @tr.update(score: 1)
      FactoryBot.create(
        :test_result,
        host: FactoryBot.create(:host, org_id: @account.org_id),
        profile: @profile,
        score: 0
      )
      assert_equal 0.5, @profile.score
    end
  end

  context 'threshold' do
    setup do
      @profile = FactoryBot.create(:profile, account: @account, policy: @policy)
      @host = FactoryBot.create(:host, org_id: @account.org_id)
      FactoryBot.create(
        :test_result,
        host: @host,
        profile: @profile,
        score: 50
      )
    end

    should 'host is compliant if 50% of rules pass with a threshold of 50' do
      @policy.update(compliance_threshold: 50)
      assert @profile.reload.compliant?(@host)
    end

    should 'host is not compliant if 50% rules pass with a threshold of 51' do
      @policy.update(compliance_threshold: 51)
      assert_not @profile.reload.compliant?(@host)
    end

    should 'host is compliant if it is compliant on some policy profile' do
      p2 = FactoryBot.create(:profile, policy: @policy, account: @account)
      @policy.update(compliance_threshold: 50)
      assert @policy.compliant?(@host)
      assert p2.reload.compliant?(@host)
    end
  end

  test 'orphaned business objectives' do
    profile = FactoryBot.create(:profile, account: @account)
    bo = FactoryBot.create(:business_objective)
    title = bo.title
    profile.policy.update!(business_objective: bo)
    assert profile.reload.business_objective, bo
    profile.policy.update!(business_objective: nil)
    assert_empty BusinessObjective.where(title: title)
  end

  test 'business_objective comes from policy' do
    profile = FactoryBot.create(:profile, account: @account)
    bo = FactoryBot.create(:business_objective)
    profile.policy.update!(business_objective: bo)
    assert_equal bo, profile.business_objective
  end

  context 'destroying' do
    setup do
      @profile = FactoryBot.create(
        :profile,
        :with_rules,
        policy: @policy,
        account: @account
      )
    end

    should 'also destroys its policy if empty' do
      assert_difference('Profile.count' => -1, 'Policy.count' => -1) do
        @profile.destroy
      end
    end

    should 'also destroys its policy having more profiles' do
      FactoryBot.create(
        :profile,
        account: @account,
        policy: @policy,
        external: true
      )

      assert_difference('Profile.count' => -2, 'Policy.count' => -1) do
        @profile.destroy
      end
    end

    should 'also destroys its related test results' do
      FactoryBot.create(
        :test_result,
        profile: @profile,
        host: FactoryBot.create(:host, org_id: @account.org_id)
      )

      assert_equal 1, @profile.test_results.count
      assert_difference('Profile.count' => -1, 'TestResult.count' => -1) do
        @profile.destroy
      end
    end

    should 'also destroys its related rule results' do
      tr = FactoryBot.create(
        :test_result,
        profile: @profile,
        host: FactoryBot.create(:host, org_id: @account.org_id)
      )

      FactoryBot.create(
        :rule_result,
        host: tr.host,
        rule: @profile.rules.first,
        test_result: tr
      )
      assert_equal 1, @profile.rule_results.count
      assert_difference('Profile.count' => -1, 'RuleResult.count' => -1) do
        @profile.destroy
      end
    end
  end

  test 'canonical profiles have no parent_profile_id' do
    assert Profile.new.canonical?, 'nil parent_profile_id should be canonical'
  end

  test 'non-canonical profiles have a parent_profile_id' do
    assert_not FactoryBot.create(:profile, account: @account).canonical?,
               'non-nil parent_profile_id should not be canonical'
  end

  test 'canonical scope finds only canonical profiles' do
    p1 = FactoryBot.create(:profile, account: @account)
    p2 = FactoryBot.create(:canonical_profile)
    assert_includes Profile.canonical, p2
    assert_not_includes Profile.canonical, p1
  end

  test 'canonical_for_os scope' do
    @os_minor_version = '1'
    profile = FactoryBot.create(:canonical_profile)
    os_major_version = profile.os_major_version
    assert os_major_version

    Xccdf::Benchmark
      .expects(:latest_for_os)
      .with(os_major_version, @os_minor_version)
      .returns(Xccdf::Benchmark.where(id: profile.benchmark.id))

    found = Profile.canonical_for_os(
      profile.os_major_version, @os_minor_version
    ).first
    assert_equal profile, found
  end

  context 'in_policy scope' do
    setup do
      @profile = FactoryBot.create(:profile, account: @account, policy: @policy)
    end

    should 'find by exact profile id' do
      assert_includes Profile.in_policy(@profile.id), @profile
      assert_equal 1, Profile.in_policy(@profile.id).length
    end

    should 'find all policy profiles with policy id provided' do
      p2 = FactoryBot.create(
        :profile,
        parent_profile: @profile.parent_profile,
        external: true,
        account: @account,
        policy: @policy
      )

      returned_profiles = Profile.in_policy(@policy.id)
      assert_includes returned_profiles, @profile
      assert_includes returned_profiles, p2
      assert_equal 2, returned_profiles.length
    end

    should 'find all policy profiles with any policy profile id provided' do
      # set different UUIDs on profiles, as they share
      # the same labels/uuids with policies.
      p2 = FactoryBot.create(
        :profile,
        parent_profile: @profile.parent_profile,
        external: true,
        account: @account,
        policy: @policy
      )

      returned_profiles = Profile.in_policy(p2.id)
      assert_includes returned_profiles, @profile
      assert_includes returned_profiles, p2
      assert_equal 2, returned_profiles.length
    end

    should 'find nothing on invalid UUID' do
      assert_equal Profile.none, Profile.in_policy('bogus')
    end
  end

  context 'first_by_os_minor_version_preferred' do
    setup do
      @os_minor_version = '1'
      @profile1 = FactoryBot.create(
        :profile,
        os_minor_version: @os_minor_version,
        account: @account
      )
      @profile2 = FactoryBot.create(
        :profile,
        parent_profile: @profile1.parent_profile,
        account: @account,
        policy: @policy
      )
    end

    should 'prefer profile with exact OS minor' do
      scoped = Profile.where(id: [@profile1, @profile2])
      assert_equal @profile1,
                   scoped.first_by_os_minor_version_preferred(@os_minor_version)
    end

    should 'fallbacks to empty OS minor version' do
      scoped = Profile.where(id: [@profile2])
      assert_equal @profile2,
                   scoped.first_by_os_minor_version_preferred(@os_minor_version)
    end
  end

  test 'has_test_results filters by test results available' do
    host = FactoryBot.create(:host, org_id: @account.org_id)
    profile1 = FactoryBot.create(:profile, account: @account)
    profile2 = FactoryBot.create(:profile, account: @account)
    FactoryBot.create(:test_result, profile: profile1, host: host)

    assert profile1.test_results.present?
    assert profile2.test_results.empty?
    assert_includes(Profile.search_for('has_test_results = true'), profile1)
    assert_not_includes(Profile.search_for('has_test_results = true'), profile2)
    assert_includes(Profile.search_for('has_test_results = false'), profile2)
    assert_not_includes(Profile.search_for('has_test_results = false'),
                        profile1)
  end

  context 'with hosts and test results' do
    setup do
      @profile1, @profile2 = FactoryBot.create_list(:profile, 2,
                                                    account: @account,
                                                    policy: @policy)

      host = FactoryBot.create(:host, org_id: @account.org_id)
      FactoryBot.create_list(:test_result, 2, profile: @profile1, host: host)
    end

    context 'policy_test_results' do
      should 'return all test results on the policy' do
        assert_not_empty @policy.test_results
        assert_equal @policy.test_results,
                     @profile1.policy_test_results
        assert_equal @policy.test_results,
                     @profile2.policy_test_results
      end
    end

    context 'policy_test_result_hosts' do
      should 'return all test result hosts on the policy' do
        assert_not_empty @policy.test_result_hosts
        assert_equal Set.new(@policy.test_result_hosts),
                     Set.new(@profile1.policy_test_result_hosts)
        assert_equal Set.new(@policy.test_result_hosts),
                     Set.new(@profile2.policy_test_result_hosts)
      end
    end
  end

  context 'has_policy_test_results filter' do
    setup do
      @profile1 = FactoryBot.create(:profile, account: @account)
      @profile2 = FactoryBot.create(:profile, account: @account)
      host = FactoryBot.create(:host, org_id: @account.org_id)
      FactoryBot.create(:test_result, profile: @profile1, host: host)
    end

    should 'find a policy profile if it has a test result' do
      @profile1.update!(policy: @policy)

      assert @profile1.test_results.present?
      assert @profile2.test_results.empty?

      assert_includes(Profile.search_for('has_policy_test_results = true'),
                      @profile1)
      assert_not_includes(Profile.search_for('has_policy_test_results = true'),
                          @profile2)
      assert_includes(Profile.search_for('has_policy_test_results = false'),
                      @profile2)
      assert_not_includes(Profile.search_for('has_policy_test_results = false'),
                          @profile1)
    end

    should 'find a policy profile if it has a test result on a scope change' do
      @profile1.update!(policy: @policy)

      assert @profile1.test_results.present?
      assert @profile2.test_results.empty?

      Profile.where(account: @account).scoping do
        assert_includes(Profile.search_for('has_policy_test_results = true'),
                        @profile1)
        assert_not_includes(
          Profile.search_for('has_policy_test_results = true'),
          @profile2
        )
        assert_includes(Profile.search_for('has_policy_test_results = false'),
                        @profile2)
        assert_not_includes(
          Profile.search_for('has_policy_test_results = false'),
          @profile1
        )
      end
    end

    should 'find all policy profiles if one has a test result' do
      @profile1.update!(policy: @policy, external: true)
      @profile2.update!(policy: @policy, external: false)

      assert @profile1.test_results.present?
      assert @profile2.test_results.empty?
      assert_includes(Profile.search_for('has_policy_test_results = true'),
                      @profile2)
      assert_not_includes(Profile.search_for('has_policy_test_results = false'),
                          @profile2)
      assert_includes(Profile.search_for('has_policy_test_results = true'),
                      @profile1)
      assert_not_includes(Profile.search_for('has_policy_test_results = false'),
                          @profile1)
    end
  end

  test 'canonical is searchable' do
    profile = FactoryBot.create(:profile, account: @account).parent_profile

    assert_includes Profile.search_for('canonical = true'), profile
    assert_not_includes Profile.search_for('canonical = false'), profile
  end

  test 'external is searchable' do
    profile = FactoryBot.create(:profile, account: @account, external: true)

    assert_includes Profile.search_for('external = true'), profile
    assert_includes Profile.external, profile
    assert_not_includes Profile.search_for('external = false'), profile
    assert_not_includes Profile.external(false), profile
  end

  test 'os_major_version scope' do
    p61a = FactoryBot.create(:canonical_profile, os_major_version: 6)
    p61b = FactoryBot.create(:canonical_profile, os_major_version: 6)
    p62 = FactoryBot.create(:canonical_profile, os_major_version: 6)
    p7 = FactoryBot.create(:canonical_profile, os_major_version: 7)
    p8 = FactoryBot.create(:canonical_profile, os_major_version: 8)

    assert_equal Set.new(Profile.os_major_version(6).to_a),
                 Set.new([p61a, p61b, p62])
    assert_equal Profile.os_major_version(7).to_a, [p7]
    assert_equal Profile.os_major_version(8).to_a, [p8]

    assert_equal Set.new(Profile.os_major_version(8, false).to_a),
                 Set.new(Profile.where.not(id: p8.id).to_a)
    assert_equal Set.new(Profile.os_major_version(6, false).to_a),
                 Set.new([p7, p8])
  end

  test 'os_major_version scoped_search' do
    p61a = FactoryBot.create(:canonical_profile, os_major_version: 6)
    p61b = FactoryBot.create(:canonical_profile, os_major_version: 6)
    p62 = FactoryBot.create(:canonical_profile, os_major_version: 6)
    p7 = FactoryBot.create(:canonical_profile, os_major_version: 7)
    p8 = FactoryBot.create(:canonical_profile, os_major_version: 8)

    assert_equal Set.new(Profile.search_for('os_major_version = 6').to_a),
                 Set.new([p61a, p61b, p62])
    assert_equal Set.new(Profile.search_for('os_major_version = 7').to_a),
                 Set.new([p7])
    assert_equal Profile.search_for('os_major_version = 8').to_a, [p8]

    assert_equal Set.new(Profile.search_for('os_major_version != 8').to_a),
                 Set.new(Profile.where.not(id: p8.id).to_a)
    assert_equal Set.new(Profile.search_for('os_major_version != 6').to_a),
                 Set.new([p7, p8])
  end

  context '#ssg_versions' do
    setup do
      @profile = FactoryBot.create(:profile, account: @account)
      @profile.benchmark.update!(version: '0.1.234')
    end

    should 'scope should allow single values' do
      assert_includes Profile.ssg_versions('0.1.234'), @profile
      assert_includes Profile.search_for('ssg_version=0.1.234'), @profile
    end

    should 'scoped_search should allow single values' do
      assert_includes Profile.search_for('ssg_version = 0.1.234'),
                      @profile
      assert_not_includes Profile.search_for('ssg_version != 0.1.234'),
                          @profile
    end

    should 'scope should allow multiple values' do
      assert_includes Profile.ssg_versions(['0.1.234', 'foo']), @profile
      assert_not_includes Profile.ssg_versions(['foo']), @profile
    end
  end

  test 'short_ref_id' do
    profile = FactoryBot.create(
      :profile,
      account: @account,
      ref_id: 'xccdf_org.ssgproject.content_profile_one'
    )

    assert_equal profile.short_ref_id, 'one'

    profile.update!(ref_id: 'xccdf_org.ssgproject.profile')
    assert_equal profile.short_ref_id, 'xccdf_org.ssgproject.profile'
  end

  context 'fill_from_parent' do
    NAME = 'Customized profile'
    DESCRIPTION = 'The best profile ever'

    setup do
      @parent = FactoryBot.create(:canonical_profile)
    end

    should 'copy attributes from the parent profile' do
      profile = Profile.new(
        parent_profile_id: @parent.id, account_id: @account.id
      ).fill_from_parent

      assert_equal @parent.ref_id, profile.ref_id
      assert_equal @parent.name, profile.name
      assert_equal @parent.description, profile.description
      assert_equal @parent.benchmark_id, profile.benchmark_id
      assert_not profile.external
    end

    should 'allow some customized attributes' do
      profile = Profile.new(name: NAME,
                            description: DESCRIPTION,
                            ref_id: 'this should be a noop',
                            benchmark_id: 'this should be a noop',
                            parent_profile_id: @parent.id)
                       .fill_from_parent

      assert_equal @parent.ref_id, profile.ref_id
      assert_equal NAME, profile.name
      assert_equal DESCRIPTION, profile.description
      assert_equal @parent.benchmark_id, profile.benchmark_id
      assert_not profile.external
    end
  end

  context 'update_rules' do
    setup do
      @profile = FactoryBot.create(:profile, :with_rules, account: @account)
    end

    should 'add new rules to an empty rule set' do
      @profile.update!(rules: [])
      assert_empty(@profile.rules)
      benchmark_rules_count = @profile.benchmark.rules.count
      assert_difference(
        '@profile.rules.count', benchmark_rules_count
      ) do
        changes = @profile.update_rules(
          ids: @profile.benchmark.rules.pluck(:id)
        )
        assert_equal [benchmark_rules_count, 0], changes
      end
    end

    should 'add new rules to an existing rule set' do
      @profile.update!(rules: @profile.rules[0...-1])
      assert_not_empty(@profile.rules)
      assert_difference('@profile.rules.count', 1) do
        changes = @profile.update_rules(
          ids: @profile.benchmark.rules.pluck(:id)
        )
        assert_equal [1, 0], changes
      end
    end

    should 'remove old rules from an existing rule set' do
      @profile.rules = @profile.benchmark.rules
      @profile.parent_profile.rules.delete_all
      assert_not_empty(@profile.rules)

      rules_count = @profile.rules.count
      assert_difference('@profile.rules.count', -rules_count) do
        changes = @profile.update_rules(
          ids: []
        )
        assert_equal [0, rules_count], changes
      end
    end

    should 'add new and remove old rules from an existing rule set' do
      original_rule_ids = @profile.rules.pluck(:id)
      @profile.update!(rule_ids: original_rule_ids[0...-1])
      assert_not_empty(@profile.rules)
      assert_difference('@profile.rules.count', 0) do
        changes = @profile.update_rules(
          ids: original_rule_ids[1..-1]
        )
        assert_equal [1, 1], changes
      end
    end
  end

  context 'cloning profile to account' do
    setup do
      PolicyHost.destroy_all
      @profile = FactoryBot.create(
        :canonical_profile,
        :with_rules,
        policy: @policy
      )
    end

    should 'use the same profile when the host is assinged' do
      host = FactoryBot.create(:host, org_id: @account.org_id)
      @policy.hosts << host

      FactoryBot.create(
        :test_result,
        profile: FactoryBot.create(
          :profile,
          policy: @policy,
          parent_profile: @profile,
          account: @account,
          ref_id: @profile.ref_id,
          benchmark: @profile.benchmark
        ),
        host: host
      )

      dupe = @profile.dup
      dupe.assign_attributes(external: true)

      assert_difference('Profile.count' => 0, 'Policy.count' => 0,
                        'PolicyHost.count' => 0) do
        cloned_profile = dupe.clone_to(
          account: @account,
          policy: Policy.with_hosts(host)
                        .find_by(account: @account)
        )

        assert_equal cloned_profile.reload.policy_id, @policy.id
        assert_includes @policy.reload.profiles, @profile
      end
    end

    should 'assign different SSG profile to a policy the host is part of' do
      host = FactoryBot.create(:host, org_id: @account.org_id)
      @policy.hosts << host

      second_benchmark = @profile.benchmark.dup
      second_benchmark.update!(version: '0.0.7')

      dupe = @profile.dup
      dupe.update!(account: nil, benchmark: second_benchmark)

      assert_difference('Profile.count' => 1, 'Policy.count' => 0,
                        'PolicyHost.count' => 0) do
        cloned_profile = dupe.clone_to(
          account: @account,
          policy: Policy.with_hosts(host)
                        .find_by(account: @account)
        )

        assert_equal cloned_profile.reload.policy_id, @policy.id
        assert_includes @policy.reload.profiles, cloned_profile
      end
    end

    should 'set the parent profile ID to the original profile' do
      host = FactoryBot.create(:host, org_id: @account.org_id)

      assert @profile.canonical?
      assert_difference('Profile.count', 1) do
        cloned_profile = @profile.clone_to(
          account: @account,
          policy: Policy.with_hosts(host)
                        .find_by(account: @account)
        )

        assert_equal @profile, cloned_profile.parent_profile
      end
    end

    should 'clone profiles as external by default' do
      host = FactoryBot.create(:host, org_id: @account.org_id)
      assert_difference('PolicyHost.count' => 0, 'Profile.count' => 1) do
        cloned_profile = @profile.clone_to(
          account: @account,
          policy: Policy.with_hosts(host)
                        .find_by(account: @account)
        )
        assert_not host.assigned_profiles.include?(cloned_profile)
        assert_nil cloned_profile.policy
      end
    end

    should 'not add rules to existing profiles' do
      assert_not_empty(@profile.rules)
      host = FactoryBot.create(:host, org_id: @account.org_id)
      @policy.hosts << host

      existing_profile = @profile.clone_to(
        account: @account,
        policy: Policy.with_hosts(host).find_by(account: @account)
      )

      existing_profile.update!(rules: [])
      assert_difference('PolicyHost.count' => 0,
                        'Profile.count' => 0,
                        'ProfileRule.count' => 0) do
        cloned_profile = @profile.clone_to(
          account: @account,
          policy: Policy.with_hosts(host)
                        .find_by(account: @account)
        )

        assert host.assigned_profiles.include?(cloned_profile)
      end
      assert_empty(existing_profile.rules)
    end
  end

  context 'profile tailoring' do
    setup do
      @parent = FactoryBot.create(
        :canonical_profile,
        :with_rules,
        rule_count: 1
      )

      @rule1 = @parent.rules.first
      @rule2 = FactoryBot.create(:rule, benchmark: @parent.benchmark)
      @rule3 = FactoryBot.create(:rule, benchmark: @parent.benchmark)

      @profile = @parent.clone_to(
        account: @account,
        policy: @policy
      )
      @profile.update! rules: [@rule2, @rule3]
      @rule2.update(precedence: 4)
      @rule3.update(precedence: 1)
    end

    should 'send the correct rule ref ids to the tailoring file service' do
      assert_equal({ @rule1.ref_id => false, @rule2.ref_id => true, @rule3.ref_id => true },
                   @profile.tailored_rule_ref_ids)
    end

    should 'properly detects added_rules in the correct order' do
      assert_equal [@rule3, @rule2], @profile.added_rules
    end

    should 'properly detects removed_rules' do
      assert_equal [@rule1], @profile.removed_rules
    end
  end
end
