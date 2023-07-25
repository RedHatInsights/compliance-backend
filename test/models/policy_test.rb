# frozen_string_literal: true

require 'test_helper'

class PolicyTest < ActiveSupport::TestCase
  should have_many(:profiles)
  should have_many(:benchmarks)
  should have_many(:test_results).through(:profiles)
  should have_many(:policy_hosts)
  should have_many(:hosts).through(:policy_hosts).source(:host)
  should have_many(:test_result_hosts).through(:test_results).source(:host)
  should belong_to(:business_objective).optional
  should belong_to(:account)

  setup do
    @user = FactoryBot.create(:user)
    @account = @user.account
    @policy = FactoryBot.create(:policy, account: @account)
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    stub_rbac_permissions(Rbac::INVENTORY_VIEWER)
  end

  context 'scopes' do
    setup do
      @hosts = FactoryBot.create_list(
        :host,
        2,
        org_id: @account.org_id
      )
    end

    should '#with_hosts accepts multiple hosts' do
      @policy.update!(hosts: [@hosts.first])

      assert_empty Policy.with_hosts([@hosts.last])
      assert_includes Policy.with_hosts([@hosts.first]), @policy

      @policy.update!(hosts: @hosts)

      assert_includes Policy.with_hosts(@hosts), @policy
    end

    should '#with_hosts accepts single hosts' do
      @policy.update!(hosts: [@hosts.first])

      assert_empty Policy.with_hosts(@hosts.last)
      assert_includes Policy.with_hosts(@hosts.first), @policy

      @policy.update!(hosts: @hosts)

      assert_includes Policy.with_hosts(@hosts.first), @policy
      assert_includes Policy.with_hosts(@hosts.last), @policy
    end

    context '#with_ref_ids' do
      setup do
        @p1 = FactoryBot.create(:profile, account: @account, policy: @policy)
        @p2 = FactoryBot.create(:profile, account: @account, policy: nil)
      end

      should '#with_ref_ids accepts multiple ref_ids' do
        assert_empty Policy.with_ref_ids([@p2.ref_id])
        assert_includes Policy.with_ref_ids([@p1.ref_id]), @policy

        @policy.update!(profiles: [@p1, @p2])
        assert_includes Policy.with_ref_ids([@p1, @p2].map(&:ref_id)), @policy
      end

      should '#with_ref_ids accepts single ref_ids' do
        assert_empty Policy.with_ref_ids(@p2.ref_id)
        assert_includes Policy.with_ref_ids(@p1.ref_id), @policy

        @policy.update!(profiles: [@p1, @p2])

        assert_includes Policy.with_ref_ids(@p1.ref_id), @policy
        assert_includes Policy.with_ref_ids(@p2.ref_id), @policy
      end
    end
  end

  should '#attrs_from(profile:)' do
    profile = FactoryBot.create(:profile, account: @account)

    Policy::PROFILE_ATTRS.each do |attr|
      assert_equal profile.send(attr),
                   Policy.attrs_from(profile: profile)[attr]
    end
  end

  context 'fill_from' do
    should 'copy attributes from the profile' do
      profile = FactoryBot.create(:profile, account: @account)
      policy = Policy.new.fill_from(profile: profile)
      assert_equal profile.name, policy.name
      assert_equal profile.description, policy.description
    end
  end

  context 'supported_os_minor_versions' do
    should 'return supported os minor versions' do
      account = FactoryBot.create(:user).account
      supported_ssg1 = SupportedSsg.new(version: '0.1.50',
                                        os_major_version: '7', os_minor_version: '1')
      SupportedSsg.stubs(:all).returns([supported_ssg1])
      bm1 = FactoryBot.create(
        :benchmark,
        version: supported_ssg1.version,
        os_major_version: '7'
      )
      SupportedSsg.stubs(:by_ssg_version).returns({ bm1.version => [supported_ssg1] })
      policy = FactoryBot.create(:policy, account: account)
      profile = FactoryBot.create(:profile, account: account, policy: policy, benchmark: bm1)
      profile.parent_profile.update!(upstream: false)

      assert_equal policy.supported_os_minor_versions, ['1']
    end
  end

  context 'update_hosts' do
    setup do
      @hosts = FactoryBot.create_list(
        :host,
        2,
        org_id: @account.org_id
      ).map { |wh| Host.find(wh.id) }
    end

    HOST_COUNT_FIELDS = %w[
      @policy.reload.hosts.count
      @policy.total_host_count
    ].freeze

    should 'update_os_minor_versions' do
      @policy.update(hosts: [@hosts.first])

      @policy.expects(:update_os_minor_versions)

      @policy.update_hosts([], @user)
    end

    should 'add new hosts to an empty host set' do
      profile = FactoryBot.create(:profile, account: @account, policy: @policy, upstream: false)

      stub_supported_ssg(@hosts, [profile.benchmark.version])

      assert_empty(@policy.hosts)
      assert_difference(HOST_COUNT_FIELDS, @hosts.count) do
        changes = @policy.update_hosts(@hosts.pluck(:id), @user)
        assert_equal [@hosts.count, 0], changes
      end
    end

    should 'add new hosts to an existing host set' do
      profile = FactoryBot.create(:profile, account: @account, policy: @policy, upstream: false)
      @policy.update(hosts: [@hosts.first])
      @policy.update_counters!

      stub_supported_ssg(@hosts, [profile.benchmark.version])

      assert_not_empty(@policy.hosts)
      assert_difference(HOST_COUNT_FIELDS, 1) do
        changes = @policy.update_hosts(@hosts.pluck(:id), @user)
        assert_equal [1, 0], changes
      end
    end

    should 'remove old hosts from an existing host set' do
      @policy.update(hosts: @hosts)
      @policy.update_counters!

      assert_equal @hosts.count, @policy.hosts.count
      assert_equal @hosts.count, @policy.total_host_count
      assert_difference(HOST_COUNT_FIELDS, -@hosts.count) do
        changes = @policy.update_hosts([], @user)
        assert_equal [0, @hosts.count], changes
      end
    end

    should 'add new and remove old hosts from an existing host set' do
      @policy.update(hosts: [@hosts.first])
      @policy.update_counters!

      profile = FactoryBot.create(:profile, account: @account, policy: @policy, upstream: false)

      stub_supported_ssg(@hosts, [profile.benchmark.version])

      assert_not_empty(@policy.hosts)
      assert_difference(HOST_COUNT_FIELDS, 0) do
        changes = @policy.update_hosts([@hosts.last.id], @user)
        assert_equal [1, 1], changes
      end
    end
  end

  should 'return an OS major version' do
    profile = FactoryBot.create(
      :profile,
      policy: @policy,
      account: @account,
      os_major_version: '6'
    )

    assert_equal '6', profile.policy.os_major_version
  end

  context 'destroy_orphaned_business_objective' do
    setup do
      @bo = FactoryBot.create(:business_objective)

      assert_empty @bo.policies
      @policy.update!(business_objective: @bo)
    end

    should 'destroy business objectives without policies on update' do
      assert_audited_success 'Autoremoved orphaned Business Objectives'
      assert_difference('BusinessObjective.count' => -1) do
        @policy.update!(business_objective: nil)
      end
    end

    should 'destroy business objectives without policies on destroy' do
      assert_audited_success 'Autoremoved orphaned Business Objectives'
      assert_difference('BusinessObjective.count' => -1) do
        Policy.where(id: @policy.id).destroy_all
      end
    end
  end

  context 'compliant?' do
    should 'be compliant if score is above compliance threshold' do
      host = FactoryBot.create(:host, org_id: @account.org_id)
      FactoryBot.create(:profile, policy: @policy, account: @account)
      @policy.update(compliance_threshold: 90, hosts: [host])
      @policy.stubs(:score).returns(95)

      assert @policy.compliant?(host)

      @policy.update!(compliance_threshold: 96)
      assert_not @policy.compliant?(host)
    end
  end

  context 'score' do
    should 'return the associated profile score' do
      test_results = 2.times.map do
        profile = FactoryBot.create(
          :profile,
          account: @account,
          policy: @policy
        )

        host = FactoryBot.create(
          :host,
          org_id: @account.org_id,
          policies: [@policy]
        )

        FactoryBot.create(:test_result, profile: profile, host: host)
      end

      assert_equal test_results[0].score,
                   @policy.score(host: test_results[0].host)
      assert_equal test_results[1].score,
                   @policy.score(host: test_results[1].host)
    end
  end

  context '#clone_to' do
    setup do
      @canonical = FactoryBot.create(:canonical_profile)
      @host = FactoryBot.create(:host, org_id: @account.org_id)
      @policy.update(hosts: [@host])
      @os_minor_version = '3'
    end

    context 'with existing profile' do
      setup do
        @profile = Profile.new(parent_profile: @canonical,
                               account: @account,
                               policy: @policy).fill_from_parent
        @profile.save!
      end

      should 'use existing profile' do
        assert_difference('Profile.count', 0) do
          child_profile = @canonical.clone_to(
            account: @account,
            policy: @policy,
            os_minor_version: @os_minor_version
          )

          assert_equal @profile, child_profile
          assert_equal @profile.os_minor_version, child_profile.os_minor_version
        end
      end

      should 'use existing profile even without providing OS minor version' do
        assert_difference('Profile.count', 0) do
          child_profile = @canonical.clone_to(
            account: @account,
            policy: @policy
          )
          assert_equal @profile, child_profile
          assert_equal @profile.os_minor_version, child_profile.os_minor_version
        end
      end

      should 'prefer existing profiles by OS version' do
        (second_profile = @profile.dup).update!(
          external: true,
          os_minor_version: @os_minor_version
        )

        child_profile = @canonical.clone_to(
          account: @account,
          policy: @profile.policy,
          os_minor_version: @os_minor_version
        )
        assert_equal second_profile, child_profile
        assert_equal second_profile.os_minor_version,
                     child_profile.os_minor_version
      end

      should 'set OS minor version on existing policy profile' do
        assert_difference('Profile.count', 0) do
          child_profile = @canonical.clone_to(
            account: @account,
            policy: @policy,
            set_os_minor_version: @os_minor_version
          )

          assert_equal @profile, child_profile
          assert_equal @os_minor_version, child_profile.os_minor_version
        end
      end

      should 'create new profile on OS minor missmatch' do
        @profile.update!(os_minor_version: '4')

        assert_difference('Profile.count', 1) do
          child_profile = @canonical.clone_to(
            account: @account,
            policy: @policy,
            set_os_minor_version: @os_minor_version
          )

          assert_not_equal @profile, child_profile
          assert_equal @account, child_profile.account
          assert_equal @policy, child_profile.policy
          assert_equal @os_minor_version, child_profile.os_minor_version
        end
      end
    end

    should 'create new profile and set OS minor version' do
      assert_difference('Profile.count', 1) do
        child_profile = @canonical.clone_to(
          account: @account,
          policy: @policy,
          set_os_minor_version: @os_minor_version
        )

        assert child_profile
        assert_equal @account, child_profile.account
        assert_equal @policy, child_profile.policy
        assert_equal @os_minor_version, child_profile.os_minor_version
      end
    end
  end

  context 'update_os_minor_versions' do
    setup do
      @profile = FactoryBot.create(:profile, account: @account, policy: @policy)
      @host = FactoryBot.create(
        :host,
        org_id: @account.org_id,
        os_minor_version: 4
      )
      @policy.update(hosts: [@host])
      @os_minor_version = '3'
      SupportedSsg.stubs(:for_os).returns([])
    end

    should 'update initial_profile when host has the latest minor version' do
      SupportedSsg.expects(:for_os).with('7', 4).returns(
        [
          SupportedSsg.new(
            os_major_version: 7,
            os_minor_version: 4,
            version: @profile.benchmark.version
          )
        ]
      )

      @profile.policy.update_os_minor_versions

      assert_equal @profile.reload.os_minor_version, '4'
    end

    context 'child profiles' do
      setup do
        @new_profile = FactoryBot.create(
          :canonical_profile,
          ref_id: @profile.parent_profile.ref_id
        )

        SupportedSsg.stubs(:for_os).with('7', 4).returns(
          [
            SupportedSsg.new(
              os_major_version: 7,
              os_minor_version: 4,
              version: @new_profile.benchmark.version
            )
          ]
        )
      end

      should 'create a new profile when it does not exist' do
        @profile.policy.update_os_minor_versions

        assert_equal @profile.reload.os_minor_version, ''
        assert_equal @profile.policy.profiles.external(true)
                             .first.os_minor_version, '4'
      end

      should 'update existing profile according the minor version' do
        child_profile = @new_profile.clone_to(
          account: @account,
          policy: @policy
        )

        @profile.policy.update_os_minor_versions

        assert_equal @profile.reload.os_minor_version, ''
        assert_equal child_profile.reload.os_minor_version, '4'
      end

      context 'multiple supported benchmarks with older assigned version' do
        should 'not touch the newer profile' do
          @profile.benchmark.update!(version: '0.1.49')
          @profile.update!(os_minor_version: '9')

          @new_profile.benchmark.update!(version: '0.1.52')

          child_profile = @new_profile.clone_to(
            account: @account,
            policy: @profile.policy
          )

          Host.expects(:os_minor_versions).returns([9])

          @profile.policy.update_os_minor_versions

          assert_equal @profile.reload.os_minor_version, '9'
          assert_equal child_profile.reload.os_minor_version, ''
        end
      end
    end
  end

  context 'cached host counts' do
    setup do
      @host1 = FactoryBot.create(:host, org_id: @account.org_id)
      @host2 = FactoryBot.create(:host, org_id: @account.org_id)
      @profile = FactoryBot.create(:profile, policy: @policy, account: @account)
    end

    should 'change the test result host count when test results are assigned' do
      FactoryBot.create(
        :test_result,
        host: @host1,
        profile: @profile,
        score: 100
      )
      assert_equal(@policy.reload.test_result_host_count, 1)
      assert_equal(@policy.reload.compliant_host_count, 1)

      FactoryBot.create(
        :test_result,
        host: @host2,
        profile: @profile,
        score: 0,
        supported: false
      )
      assert_equal(@policy.reload.test_result_host_count, 1)
      assert_equal(@policy.reload.compliant_host_count, 1)
      assert_equal(@policy.reload.unsupported_host_count, 1)

      FactoryBot.create(
        :test_result,
        host: @host2,
        profile: @profile,
        score: 0
      )
      assert_equal(@policy.reload.test_result_host_count, 2)
      assert_equal(@policy.reload.compliant_host_count, 1)
      assert_equal(@policy.reload.unsupported_host_count, 0)

      FactoryBot.create(
        :test_result,
        host: @host2,
        profile: @profile,
        score: 100
      )
      assert_equal(@policy.reload.test_result_host_count, 2)
      assert_equal(@policy.reload.compliant_host_count, 2)
      assert_equal(@policy.reload.unsupported_host_count, 0)

      @profile.test_results.destroy_all
      assert_equal(@policy.reload.test_result_host_count, 0)
      assert_equal(@policy.reload.compliant_host_count, 0)
      assert_equal(@policy.reload.unsupported_host_count, 0)
    end
  end
end
