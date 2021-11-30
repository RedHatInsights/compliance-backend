# frozen_string_literal: true

require 'test_helper'

class OsMajorVersionTest < ActiveSupport::TestCase
  context 'supported_profiles' do
    should 'list all supported profiles' do
      v1 = SupportedSsg.by_os_major['7'].first
      bm1 = FactoryBot.create(
        :benchmark,
        version: v1.version,
        os_major_version: '7'
      )

      v2 = SupportedSsg.by_os_major['7'].last
      bm2 = FactoryBot.create(
        :benchmark,
        version: v2.version,
        os_major_version: '7'
      )

      bm3 = FactoryBot.create(
        :benchmark,
        version: '0.0.1',
        os_major_version: '7'
      )

      p1 = FactoryBot.create(:canonical_profile, benchmark: bm1)
      p2 = FactoryBot.create(:canonical_profile, benchmark: bm2)
      p3 = FactoryBot.create(:canonical_profile, benchmark: bm3)

      result = OsMajorVersion.first.supported_profiles

      assert_includes(result, p1)
      assert_includes(result, p2)
      assert_not_includes(result, p3)
    end
  end
end
