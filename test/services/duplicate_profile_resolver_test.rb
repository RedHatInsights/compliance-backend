# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200325185540_add_unique_index_to_profiles'

class DuplicateProfileResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      ActiveRecord::Migration.suppress_messages do
        AddUniqueIndexToProfiles.new.down
      end
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

  test 'resolves children profiles' do
    profiles(:two).update!(parent_profile: @dup_profile,
                           account: accounts(:test))

    assert_difference('Profile.count' => -1) do
      DuplicateProfileResolver.run!
    end

    assert_equal Profile.find_by(ref_id: profiles(:one).ref_id),
                 profiles(:two).reload.parent_profile
  end
end
