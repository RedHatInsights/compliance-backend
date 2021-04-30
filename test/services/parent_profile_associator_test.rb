# frozen_string_literal: true

require 'test_helper'

class ParentProfileAssociatorTest < ActiveSupport::TestCase
  test 'finds a single parent profile per profile' do
    Profile.delete_all
    account = FactoryBot.create(:account)
    profile = FactoryBot.create(:canonical_profile)

    child_profile = profile.dup
    child_profile.account = account
    assert child_profile.save

    assert_difference('Profile.where.not(parent_profile_id: nil).count', 1) do
      ParentProfileAssociator.run!
    end
  end
end
