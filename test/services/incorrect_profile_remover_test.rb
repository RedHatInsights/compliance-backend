# frozen_string_literal: true

require 'test_helper'

class IncorrectProfileRemoverTest < ActiveSupport::TestCase
  setup do
    profiles(:one).update!(policy_object: policies(:one),
                           account: accounts(:test))
    profiles(:two).update!(policy_object: policies(:two),
                           account: accounts(:test))
  end

  test 'removes profiles with a mismatched ref_id' do
    profiles(:one).dup.update!(ref_id: 'foo', external: true)
    assert_equal 2, policies(:one).profiles.count
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
    (bm2 = benchmarks(:one).dup).update!(version: '0.1.23')
    profiles(:one).dup.update!(benchmark: bm2, external: true)
    assert_equal 2, policies(:one).profiles.count
    assert_difference('Profile.count' => 0) do
      IncorrectProfileRemover.run!
    end
  end
end
