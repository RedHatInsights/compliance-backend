# frozen_string_literal: true

require 'test_helper'

# A class to test importing from a Datastream file
class CopyProfilesToPoliciesTest < ActiveSupport::TestCase
  fixtures :accounts, :profiles

  setup do
    Policy.destroy_all
    profiles(:one).update!(parent_profile: profiles(:two),
                           account: accounts(:test))
  end

  test 'Copies profile attributes to new policies' do
    assert_difference('Policy.count' => 1) do
      CopyProfilesToPolicies.run!
    end
    assert_not_nil(policy = profiles(:one).reload.policy_object)
    assert_equal profiles(:one).name, policy.name
    assert_equal profiles(:one).description, policy.description
    assert_equal Policy.count, Profile.external(false).canonical(false).count
  end

  test 'Copies profile hosts to new policies' do
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

  test 'associates other profiles to the policy' do
    (bm = benchmarks(:one).dup).update!(version: '0.1.46')
    (profile = profiles(:one).dup).update!(parent_profile: profiles(:two),
                                           account: accounts(:test),
                                           benchmark: bm)
    assert_difference('Policy.count' => 1) do
      CopyProfilesToPolicies.run!
    end
    assert_not_nil profile.reload.policy_object
    assert_equal 2, profile.policy_object.profiles.count
    assert_equal Profile.external(false).canonical(false).uniq(&:ref_id).count,
                 Policy.count
  end
end
