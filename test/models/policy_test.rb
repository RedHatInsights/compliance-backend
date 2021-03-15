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

  context 'scopes' do
    should '#with_hosts accepts multiple hosts' do
      policies(:one).update!(hosts: [hosts(:one)])

      assert_empty Policy.with_hosts([hosts(:two)])
      assert_includes Policy.with_hosts([hosts(:one)]), policies(:one)

      policies(:one).update!(hosts: [hosts(:one), hosts(:two)])

      assert_includes Policy.with_hosts([hosts(:one), hosts(:two)]),
                      policies(:one)
    end

    should '#with_hosts accepts single hosts' do
      policies(:one).update!(hosts: [hosts(:one)])

      assert_empty Policy.with_hosts(hosts(:two))
      assert_includes Policy.with_hosts(hosts(:one)), policies(:one)

      policies(:one).update!(hosts: [hosts(:one), hosts(:two)])

      assert_includes Policy.with_hosts(hosts(:one)), policies(:one)
      assert_includes Policy.with_hosts(hosts(:two)), policies(:one)
    end

    should '#with_ref_ids accepts multiple ref_ids' do
      profiles(:one).update!(account: accounts(:test))
      profiles(:two).update!(account: accounts(:test))

      policies(:one).update!(profiles: [profiles(:one)])

      assert_empty Policy.with_ref_ids([profiles(:two).ref_id])
      assert_includes Policy.with_ref_ids([profiles(:one).ref_id]),
                      policies(:one)

      policies(:one).update!(profiles: [profiles(:one), profiles(:two)])

      assert_includes Policy.with_ref_ids([profiles(:one).ref_id,
                                           profiles(:two).ref_id]),
                      policies(:one)
    end

    should '#with_ref_ids accepts single ref_ids' do
      profiles(:one).update!(account: accounts(:test))
      profiles(:two).update!(account: accounts(:test))

      policies(:one).update!(profiles: [profiles(:one)])

      assert_empty Policy.with_ref_ids(profiles(:two).ref_id)
      assert_includes Policy.with_ref_ids(profiles(:one).ref_id), policies(:one)

      policies(:one).update!(profiles: [profiles(:one), profiles(:two)])

      assert_includes Policy.with_ref_ids(profiles(:one).ref_id), policies(:one)
      assert_includes Policy.with_ref_ids(profiles(:two).ref_id), policies(:one)
    end
  end

  should '#attrs_from(profile:)' do
    profiles(:one).update!(account: accounts(:one))

    Policy::PROFILE_ATTRS.each do |attr|
      assert_equal profiles(:one).send(attr),
                   Policy.attrs_from(profile: profiles(:one))[attr]
    end
  end

  context 'fill_from' do
    should 'copy attributes from the profile' do
      policy = Policy.new.fill_from(profile: profiles(:one))
      assert_equal profiles(:one).name, policy.name
      assert_equal profiles(:one).description, policy.description
    end
  end

  context 'update_hosts' do
    should 'add new hosts to an empty host set' do
      policies(:one).update!(hosts: [])
      profiles(:one).update!(account: accounts(:test))
      policies(:one).update!(profiles: [profiles(:one)])
      profiles(:one).update!(parent_profile: profiles(:two))

      assert_empty(policies(:one).hosts)
      assert_difference('policies(:one).hosts.count', hosts.count) do
        changes = policies(:one).update_hosts(hosts.pluck(:id))
        assert_equal [hosts.count, 0], changes
      end
    end

    should 'add new hosts to an existing host set' do
      policies(:one).update!(hosts: hosts[0...-1])
      profiles(:one).update!(account: accounts(:test))
      policies(:one).update!(profiles: [profiles(:one)])

      assert_not_empty(policies(:one).hosts)
      assert_difference('policies(:one).hosts.count', 1) do
        changes = policies(:one).update_hosts(hosts.pluck(:id))
        assert_equal [1, 0], changes
      end
    end

    should 'remove old hosts from an existing host set' do
      policies(:one).update!(hosts: hosts)
      assert_equal hosts.count, policies(:one).hosts.count
      assert_difference('policies(:one).reload.hosts.count', -hosts.count) do
        changes = policies(:one).update_hosts([])
        assert_equal [0, hosts.count], changes
      end
    end

    should 'add new and remove old hosts from an existing host set' do
      policies(:one).update!(host_ids: hosts.pluck(:id)[0...-1])
      profiles(:one).update!(account: accounts(:test))
      policies(:one).update!(profiles: [profiles(:one)])

      assert_not_empty(policies(:one).hosts)
      assert_difference('policies(:one).hosts.count', 0) do
        changes = policies(:one).update_hosts(hosts.pluck(:id)[1..-1])
        assert_equal [1, 1], changes
      end
    end
  end

  should 'return an OS major version' do
    profiles(:one).update!(policy: policies(:one),
                           account: accounts(:test))
    assert_equal '7', policies(:one).os_major_version
  end

  context 'destroy_orphaned_business_objective' do
    setup do
      assert_empty business_objectives(:one).policies
      policies(:one).update!(business_objective: business_objectives(:one))
    end

    should 'destroy business objectives without policies on update' do
      assert_difference('BusinessObjective.count' => -1) do
        policies(:one).update!(business_objective: nil)
      end
      assert_audited 'Autoremoved orphaned Business Objectives'
    end

    should 'destroy business objectives without policies on destroy' do
      assert_difference('BusinessObjective.count' => -1) do
        Policy.where(id: policies(:one)).destroy_all
      end
      assert_audited 'Autoremoved orphaned Business Objectives'
    end
  end

  context 'compliant?' do
    should 'be compliant if score is above compliance threshold' do
      policies(:one).update!(compliance_threshold: 90)
      policies(:one).stubs(:score).returns(95)
      profiles(:one).update!(policy: policies(:one),
                             account: accounts(:test))

      assert policies(:one).compliant?(hosts(:one))

      policies(:one).update!(compliance_threshold: 96)

      assert_not policies(:one).compliant?(hosts(:one))
    end
  end

  context 'score' do
    should 'return the associated profile score' do
      profiles(:one).update!(policy: policies(:one),
                             account: accounts(:test))
      profiles(:two).update!(policy: policies(:one),
                             account: accounts(:test))

      assert_equal test_results(:one).score,
                   policies(:one).score(host: hosts(:one))
      assert_equal test_results(:two).score,
                   policies(:one).score(host: hosts(:two))
    end
  end

  context 'update_os_minor_versions' do
    setup do
      @profile = Profile.new(parent_profile: profiles(:two),
                             account: accounts(:one),
                             policy: policies(:one)).fill_from_parent
      policies(:one).update!(account: accounts(:one))
      @profile.save!

      @policy_host = PolicyHost.create!(
        policy: @profile.policy,
        host: hosts(:one)
      )
    end

    should 'update initial_profile when host has the latest minor version' do
      @profile.benchmark.update!(version: '0.1.33')

      @profile.policy.update_os_minor_versions

      assert_equal @profile.reload.os_minor_version, '4'
    end

    context 'child profiles' do
      setup do
        @new_benchmark = benchmarks(:one).dup
        @new_benchmark.assign_attributes(version: '0.1.33')
        @new_benchmark.save!

        @new_profile = profiles(:two).dup
        @new_profile.assign_attributes(benchmark: @new_benchmark)
        @new_profile.save!
      end

      should 'create a new profile when it does not exist' do
        @profile.policy.update_os_minor_versions

        assert_equal @profile.reload.os_minor_version, ''
        assert_equal @profile.policy.profiles.external(true)
                             .first.os_minor_version, '4'
      end

      should 'update existing profile according the minor version' do
        child_profile = @new_profile.clone_to(
          account: accounts(:one),
          policy: @profile.policy
        )

        @profile.policy.update_os_minor_versions

        assert_equal @profile.reload.os_minor_version, ''
        assert_equal child_profile.reload.os_minor_version, '4'
      end

      context 'multiple supported benchmarks with older assigned version' do
        should 'not touch the newer profile' do
          @profile.benchmark.update!(version: '0.1.49')
          @profile.update!(os_minor_version: '9')

          @new_benchmark.update!(version: '0.1.52')

          child_profile = @new_profile.clone_to(
            account: accounts(:one),
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
end
