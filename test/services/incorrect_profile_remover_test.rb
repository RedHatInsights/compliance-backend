# frozen_string_literal: true

require 'test_helper'

class IncorrectProfileRemoverTest < ActiveSupport::TestCase
  setup do
    account = FactoryBot.create(:account)
    @profile = FactoryBot.create(:profile, account: account)

    logger = mock
    Logger.stubs(:new).returns(logger)
    logger.stubs(:info)
  end

  test 'removes profiles with a mismatched ref_id' do
    @profile.dup.update!(ref_id: 'foo', external: true)
    assert_equal 2, @profile.policy.profiles.count
    assert_difference('Profile.count' => -1) do
      IncorrectProfileRemover.run!
    end
  end

  test 'does nothing to new policies with only an initial profile' do
    assert_difference('Profile.count' => 0) do
      IncorrectProfileRemover.run!
    end
  end

  test 'does nothing to policies with no mismatched profiles' do
    (bm2 = @profile.benchmark.dup).update!(version: '0.1.23')
    @profile.dup.update!(benchmark: bm2, external: true)
    assert_equal 2, @profile.policy.profiles.count
    assert_difference('Profile.count' => 0) do
      IncorrectProfileRemover.run!
    end
  end
end
