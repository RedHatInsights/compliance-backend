# frozen_string_literal: true

require 'test_helper'

# A class to test importing from a Datastream file
class CopyProfilesToPoliciesTest < ActiveSupport::TestCase
  fixtures :accounts, :profiles

  setup do
    Policy.destroy_all
    profiles(:one).update!(parent_profile: profiles(:two),
                           account: accounts(:test),
                           compliance_threshold: 75.0,
                           business_objective_id: business_objectives(:two).id)
  end

  test 'copies profile attributes to new policies' do
    assert_difference('Policy.count' => 1) do
      CopyProfilesToPolicies.run!
    end
    assert_not_nil(policy = profiles(:one).reload.policy_object)

    assert_equal profiles(:one).name, policy.name
    assert_equal profiles(:one).description, policy.description
    assert_equal profiles(:one).account_id, policy.account_id
    assert_equal profiles(:one).compliance_threshold,
                 policy.compliance_threshold
    assert_equal profiles(:one).business_objective_id,
                 policy.business_objective_id

    assert_equal Policy.count, Profile.external(false).canonical(false).count
  end

  test 'copies profile hosts to new policies' do
    profiles(:one).profile_hosts << hosts.map do |host|
      ProfileHost.create!(profile: profiles(:one), host: host)
    end
    assert_difference('Policy.count' => 1, 'PolicyHost.count' => hosts.count) do
      CopyProfilesToPolicies.run!
    end
    assert_not_nil(policy = profiles(:one).reload.policy_object)
    assert_equal Set.new(policy.hosts), Set.new(hosts)
    assert_equal Policy.count, Profile.external(false).canonical(false).count
  end

  test 'copies two similar internal profiles with to two new policies' do
    first = profiles(:one)
    (bm = benchmarks(:one).dup).update!(version: '0.1.46')
    (second = profiles(:one).dup).update!(parent_profile: profiles(:two),
                                          account: accounts(:test),
                                          benchmark: bm)
    assert_difference('Policy.count' => 2) do
      CopyProfilesToPolicies.run!
    end
    assert_not_nil first.reload.policy_object
    assert_equal 1, first.policy_object.profiles.count
    assert_not_nil second.reload.policy_object
    assert_equal 1, second.policy_object.profiles.count
    assert_equal Profile.external(false).canonical(false).count,
                 Policy.count
  end

  test 'does not create policy for external profile ' do
    # (bm = benchmarks(:one).dup).update!(version: '0.1.46')
    profiles(:one).dup.update!(external: true)
    assert_difference('Policy.count' => 1) do
      CopyProfilesToPolicies.run!
    end
    assert_not_nil profiles(:one).reload.policy_object
    assert_equal 1, profiles(:one).policy_object.profiles.count
    assert_equal Profile.external(false).canonical(false).uniq(&:ref_id).count,
                 Policy.count
  end

  test 'idempotency' do
    assert_difference('Policy.count' => 1) do
      CopyProfilesToPolicies.run!
      CopyProfilesToPolicies.run!
    end
  end
end
