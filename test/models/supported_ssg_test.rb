# frozen_string_literal: true

require 'test_helper'

class SupportedSsgTest < ActiveSupport::TestCase
  test 'loads supported SSGs' do
    assert SupportedSsg.all
  end

  test 'provides revision' do
    assert SupportedSsg.revision
  end

  context 'loaded supported SSGs' do
    setup do
      loaded = [
        SupportedSsg.new(version: '0.1.50'),
        SupportedSsg.new(version: '0.1.24'),
        SupportedSsg.new(upstream_version: '0.1.25', version: '0.1.22'),
        SupportedSsg.new(upstream_version: 'N/A', version: '0.1.1')
      ]
      SupportedSsg.stubs(:all).returns(loaded)
    end

    should 'provide models available upstream' do
      in_upstream = SupportedSsg.available_upstream
      versions = in_upstream.map(&:version)
      assert_includes versions, '0.1.50'
      assert_includes versions, '0.1.24'
      assert_includes versions, '0.1.22' # upstream version is higher
      assert_equal in_upstream.count, 3
    end
  end
end
