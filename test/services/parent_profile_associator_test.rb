# frozen_string_literal: true

require 'test_helper'

class ParentProfileAssociatorTest < ActiveSupport::TestCase
  test 'finds a single parent profile per profile' do
    child_profile = profiles(:one).dup
    child_profile.account = accounts(:test)
    assert child_profile.save

    assert_difference('Profile.where.not(parent_profile_id: nil).count', 1) do
      ParentProfileAssociator.run!
    end
  end
end
