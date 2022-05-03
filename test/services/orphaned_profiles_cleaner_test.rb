# frozen_string_literal: true

require 'test_helper'

class OrphanedProfilesCleanerTest < ActiveSupport::TestCase
  setup do
    account = FactoryBot.create(:account)
    host = FactoryBot.create(:host, account: account.account_number)
    @profile = FactoryBot.create(:profile, account: account)
    @tr = FactoryBot.create(:test_result, profile: @profile, host: host)
  end

  test 'drops the profile if it cannot be reattached' do
    @profile.policy_id = nil
    @profile.external = true
    @profile.save(validate: false)

    assert_difference('Profile.count' => -1) do
      OrphanedProfilesCleaner.run!
    end
  end

  test 'does not touch profiles with policies' do
    assert_difference('Profile.count' => 0) do
      OrphanedProfilesCleaner.run!
    end
  end
end
