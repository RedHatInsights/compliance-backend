# frozen_string_literal: true

require 'test_helper'

class OsMajorVersionTest < ActiveSupport::TestCase
  context 'supported_profiles' do
    should 'list all supported profiles' do
      supported_ssg1 = SupportedSsg.new(version: '0.1.50',
                                        os_major_version: '7', os_minor_version: '1')
      supported_ssg2 = SupportedSsg.new(version: '0.1.51',
                                        os_major_version: '7', os_minor_version: '9')
      supported_ssg3 = SupportedSsg.new(version: '0.0.1',
                                        os_major_version: '7', os_minor_version: '3')
      SupportedSsg.stubs(:all).returns([supported_ssg1, supported_ssg2, supported_ssg3])
      bm1 = FactoryBot.create(
        :benchmark,
        version: supported_ssg1.version,
        os_major_version: '7'
      )

      bm2 = FactoryBot.create(
        :benchmark,
        version: supported_ssg2.version,
        os_major_version: '7'
      )

      bm3 = FactoryBot.create(
        :benchmark,
        version: supported_ssg3.version,
        os_major_version: '7'
      )

      p1 = FactoryBot.create(:canonical_profile, upstream: false, benchmark: bm1)
      p2 = FactoryBot.create(:canonical_profile, upstream: false, benchmark: bm2)
      p3 = FactoryBot.create(:canonical_profile, upstream: true, benchmark: bm3)

      result = OsMajorVersion.first.profiles

      assert_includes(result, p1)
      assert_includes(result, p2)
      assert_not_includes(result, p3)
    end
  end

  test 'is readonly' do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      OsMajorVersion.new.save
    end
  end
end
