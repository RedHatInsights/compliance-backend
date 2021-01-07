# frozen_string_literal: true

require 'test_helper'

# A class to test removal of external policies
class ExternalPolicyRemoverTest < ActiveSupport::TestCase
  test 'does nothing if no external policies exist' do
    assert_empty Profile.external.where(policy_id: nil)
    assert_difference('Profile.count' => 0) do
      ExternalPolicyRemover.run!
    end
  end

  test 'removes all external policies' do
    profiles(:one).dup.update!(external: true, account: accounts(:test))
    profiles(:two).dup.update!(external: true, policy_object: policies(:one),
                               account: accounts(:test))
    assert_equal 1, Profile.external.where(policy_id: nil).count
    assert_difference('Profile.count' => -1) do
      ExternalPolicyRemover.run!
    end
  end
end
