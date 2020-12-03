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
        SupportedSsg.new(version: '0.1.50',
                         os_major_version: '7', os_minor_version: '3'),
        SupportedSsg.new(version: '0.1.24',
                         os_major_version: '7', os_minor_version: '2'),
        SupportedSsg.new(upstream_version: '0.1.25', version: '0.1.22',
                         os_major_version: '6', os_minor_version: '10'),
        SupportedSsg.new(upstream_version: 'N/A', version: '0.1.1',
                         os_major_version: '6', os_minor_version: '9')
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

    should 'provide models by latest in each OS major version' do
      latest = SupportedSsg.latest_per_os_major
      versions = latest.map(&:version)
      assert_includes versions, '0.1.50'
      assert_includes versions, '0.1.22'
      assert_equal latest.count, 2
    end
  end

  context 'supported?' do
    should 'return true for OS/SSG matches' do
      SupportedSsg.stubs(:ssg_for_os).returns('1.2.3')
      assert SupportedSsg.supported?(ssg_version: '1.2.3',
                                     os_major_version: '7',
                                     os_minor_version: '4')
      assert_not SupportedSsg.supported?(ssg_version: '1.2.4',
                                         os_major_version: '7',
                                         os_minor_version: '4')
    end
  end

  context 'ssg_for_os' do
    should 'return true for OS/SSG matches' do
      SupportedSsg.stubs(:raw_supported).returns(
        'supported' => {
          'RHEL-7.4' => {
            'version' => '1.2.3'
          },
          'RHEL-6.9' => {
            'version' => '0.1.2'
          }
        }
      )

      assert_equal '1.2.3', SupportedSsg.ssg_for_os(7, 4)
      assert_equal '0.1.2', SupportedSsg.ssg_for_os(6, 9)
      assert_nil SupportedSsg.ssg_for_os(8, 1)
    end
  end
end
