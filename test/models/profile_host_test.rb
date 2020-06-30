# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class ProfileHostTest < ActiveSupport::TestCase
  setup do
    DeleteHost.clear
  end

  test 'destroys associated hosts if host has no more policies assigned' do
    profile = Profile.create(name: 'foo', benchmark: benchmarks(:one),
                             ref_id: 'foo')
    host = Host.create(profiles: [profile], name: 'bar',
                       account: accounts(:one))
    assert_equal 0, DeleteHost.jobs.size
    profile.destroy
    assert_equal 1, DeleteHost.jobs.size
    assert_difference('Host.count', -1) do
      DeleteHost.drain
    end
    assert_empty Host.where(id: host.id)
    assert_equal 0, DeleteHost.jobs.size
  end

  test 'destory associated external policies if they have no more hosts' do
    internal_profile = Profile.create(name: 'foo', benchmark: benchmarks(:one),
                                      ref_id: 'foo')
    external_profile = Profile.create(name: 'baz', benchmark: benchmarks(:one),
                                      ref_id: 'baz', external: true)
    host = Host.create(profiles: [internal_profile, external_profile],
                       name: 'bar', account: accounts(:one))
    assert_difference('Profile.count', -1) do
      host.destroy
    end
    assert_equal internal_profile, Profile.find(internal_profile.id)
    assert_empty Profile.where(id: external_profile.id)
  end
end
