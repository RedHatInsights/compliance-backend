# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200325185540_add_unique_index_to_profiles'

class DuplicateProfileResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      AddUniqueIndexToProfiles.new.down
    rescue ArgumentError # if index doesn't exist
    end
    # rubocop:enable Lint/SuppressedException

    assert_difference('Profile.count' => 1) do
      (@dup_profile = profiles(:one).dup).save(validate: false)
    end
  end

  test 'resolves identical profiles' do
    assert_difference('Profile.count' => -1) do
      DuplicateProfileResolver.run!
    end
  end

  test 'resolves profile_hosts from a duplicate profile with the different '\
       'hosts' do
    assert_difference('ProfileHost.count' => 2) do
      profiles(:one).hosts << hosts(:one)
      @dup_profile.hosts << hosts(:two)
    end

    assert_difference('ProfileHost.count' => 0) do
      DuplicateProfileResolver.run!
    end
  end

  test 'resolves profile_hosts from a duplicate profile with the same hosts' do
    assert_difference('ProfileHost.count' => 2) do
      profiles(:one).hosts << hosts(:one)
      @dup_profile.hosts << hosts(:one)
    end

    assert_difference('ProfileHost.count' => -1) do
      DuplicateProfileResolver.run!
    end
  end

  test 'resolves children profiles' do
    profiles(:two).update!(parent_profile: @dup_profile)

    assert_difference('Profile.count' => -1) do
      DuplicateProfileResolver.run!
    end

    assert_equal Profile.find_by(ref_id: profiles(:one).ref_id),
                 profiles(:two).reload.parent_profile
  end
end
