# frozen_string_literal: true

require 'test_helper'

# A class to test removal of external policies
class ExternalPolicyRemoverTest < ActiveSupport::TestCase
  setup do
    logger = mock
    Logger.stubs(:new).returns(logger)
    logger.stubs(:info)
    User.current = FactoryBot.create(:user)
  end

  test 'does nothing if no external policies exist' do
    FactoryBot.create_list(:profile, 10)
    assert_empty Profile.external.where(policy_id: nil)
    assert_difference('Profile.count' => 0) do
      ExternalPolicyRemover.run!
    end
  end

  test 'removes all external policies' do
    FactoryBot.create(:profile, external: true)
    FactoryBot.create(:profile, external: true, policy: nil)

    assert_equal 1, Profile.external.where(policy_id: nil).count
    assert_difference('Profile.count' => -1) do
      ExternalPolicyRemover.run!
    end
  end
end
