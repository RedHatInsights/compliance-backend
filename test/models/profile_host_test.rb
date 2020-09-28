# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class ProfileHostTest < ActiveSupport::TestCase
  test 'destroy associated external policies if they have no more hosts' do
    internal_profile = Profile.create(name: 'foo', benchmark: benchmarks(:one),
                                      ref_id: 'foo', account: accounts(:one))
    external_profile = Profile.create(name: 'baz', benchmark: benchmarks(:one),
                                      ref_id: 'baz', external: true,
                                      account: accounts(:one))
    host = Host.create(profiles: [internal_profile, external_profile],
                       name: 'bar', account: accounts(:one))
    assert_difference('Profile.count', -1) { host.destroy }
    assert_equal internal_profile, Profile.find(internal_profile.id)
    assert_empty Profile.where(id: external_profile.id)
  end

  test 'does not destroy external policies if they still have hosts' do
    internal_profile = Profile.create(name: 'foo', benchmark: benchmarks(:one),
                                      ref_id: 'foo', account: accounts(:one))
    external_profile = Profile.create(name: 'baz', benchmark: benchmarks(:one),
                                      ref_id: 'baz', external: true,
                                      account: accounts(:one))
    host = Host.create(profiles: [internal_profile, external_profile],
                       name: 'bar', account: accounts(:one))
    another_host = Host.create(profiles: [external_profile],
                               name: 'bar2', account: accounts(:one))
    assert_difference('Profile.count', 0) { host.destroy }
    assert_equal internal_profile, Profile.find(internal_profile.id)
    assert_includes Profile.find(external_profile.id).hosts, another_host
  end
end
