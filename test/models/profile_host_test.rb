# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class ProfileHostTest < ActiveSupport::TestCase
  setup do
    @profile = profiles(:one)
    @host = hosts(:one)
    @profile_host = ProfileHost.new(profile: @profile, host: @host)
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
end
