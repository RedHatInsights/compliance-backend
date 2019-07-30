# frozen_string_literal: true

require 'test_helper'

class ProfileHostTest < ActiveSupport::TestCase
  setup do
    @profile = profiles(:one)
    @host = hosts(:one)
    @profile_host = ProfileHost.new(profile: @profile, host: @host)
  end

  test '#delete_orphaned_profiles when some other hosts still exist (noop)' do
    @profile.expects(:destroy).never
    @profile.stubs(:hosts).returns(Host.where(id: hosts(:two).id))

    @profile_host.delete_orphaned_profiles
  end

  test '#delete_orphaned_profiles when only this host exists' do
    @profile.expects(:destroy)
    @profile.stubs(:hosts).returns(Host.where(id: @host.id))

    @profile_host.delete_orphaned_profiles
  end
end
