# frozen_string_literal: true

require 'test_helper'

class PolicyTest < ActiveSupport::TestCase
  should have_many(:profiles)
  should have_many(:benchmarks)
  should have_many(:test_results).through(:profiles)
  should have_many(:policy_hosts)
  should have_many(:hosts).through(:policy_hosts).source(:host)
  should belong_to(:business_objective).optional
  should belong_to(:account)

  should '#attrs_from(profile:)' do
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
      assert_empty(policies(:one).hosts)
      assert_difference('policies(:one).hosts.count', hosts.count) do
        policies(:one).update_hosts(hosts.pluck(:id))
      end
    end

    should 'add new hosts to an existing host set' do
      policies(:one).update!(hosts: hosts[0...-1])
      assert_not_empty(policies(:one).hosts)
      assert_difference('policies(:one).hosts.count', 1) do
        policies(:one).update_hosts(hosts.pluck(:id))
      end
    end

    should 'remove old hosts from an existing host set' do
      policies(:one).update!(hosts: hosts)
      assert_equal hosts.count, policies(:one).hosts.count
      assert_difference('policies(:one).reload.hosts.count', -hosts.count) do
        policies(:one).update_hosts([])
      end
    end

    should 'add new and remove old hosts from an existing host set' do
      policies(:one).update!(host_ids: hosts.pluck(:id)[0...-1])
      assert_not_empty(policies(:one).hosts)
      assert_difference('policies(:one).hosts.count', 0) do
        policies(:one).update_hosts(hosts.pluck(:id)[1..-1])
      end
    end
  end

  should 'return an OS major version' do
    profiles(:one).update!(policy_object: policies(:one),
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
    end

    should 'destroy business objectives without policies on destroy' do
      assert_difference('BusinessObjective.count' => -1) do
        policies(:one).destroy
      end
    end
  end
end
