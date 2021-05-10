# frozen_string_literal: true

require 'test_helper'

class ExternalProfileUpdaterTest < ActiveSupport::TestCase
  test 'updates profiles before a certain date to be external' do
    expected_change = Profile.count
    date = DateTime.now
    profile = FactoryBot.create(:profile, account: FactoryBot.create(:account))

    assert_difference('Profile.where(external: false).count' => 1) do
      profile.dup.update(ref_id: 'foo')
    end

    assert_difference('Profile.where(external: true).count' =>
                      expected_change) do
      ExternalProfileUpdater.run!(date)
    end
  end
end
