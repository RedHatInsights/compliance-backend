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
        SupportedSsg.new(version: '0.1.52',
                         os_major_version: '7', os_minor_version: '3'),
        SupportedSsg.new(version: '0.1.24',
                         os_major_version: '7', os_minor_version: '2'),
        SupportedSsg.new(version: '0.1.22',
                         os_major_version: '6', os_minor_version: '10'),
        SupportedSsg.new(version: '0.1.1',
                         os_major_version: '6', os_minor_version: '9')
      ]
      SupportedSsg.stubs(:all).returns(loaded)
    end

    should 'provide models with ref_id' do
      ref_ids = SupportedSsg.all.map(&:ref_id)
      assert ref_ids.all?(&:present?)
    end

    should 'provide a map of latest supported SSG for combination of OS major' \
           ' an minor version' do
      SupportedSsg.instance_variable_set(:@latest_map, nil)
      latest_map = SupportedSsg.latest_map

      assert_equal %w[6 7], latest_map.keys.sort
      assert_equal %w[10 9], latest_map['6'].keys.sort
      assert_equal %w[2 3], latest_map['7'].keys.sort

      assert_equal '0.1.52', latest_map.dig('7', '3').version
      assert_equal '0.1.24', latest_map.dig('7', '2').version
      assert_equal '0.1.22', latest_map.dig('6', '10').version
      assert_equal '0.1.1', latest_map.dig('6', '9').version
    end

    should 'provide models by grouped by OS major' do
      by_os_major = SupportedSsg.by_os_major
      assert_equal %w[6 7], by_os_major.keys.sort
      assert_equal 2, by_os_major['6'].count
      assert_equal 3, by_os_major['7'].count
    end
  end

  context '#supported?' do
    should 'return true for OS/SSG matches' do
      SupportedSsg.stubs(:ssg_versions_for_os).returns(['0.0.1', '1.2.3'])
      assert SupportedSsg.supported?(ssg_version: '1.2.3',
                                     os_major_version: '7',
                                     os_minor_version: '4')
      assert_not SupportedSsg.supported?(ssg_version: '1.2.4',
                                         os_major_version: '7',
                                         os_minor_version: '4')
    end
  end

  context '#by_ssg_version' do
    should 'return the ssgs grouped by SSG version' do
      SupportedSsg.stubs(:raw_supported).returns(
        'supported' => {
          'RHEL-7.4' => [
            { 'version' => '1.2.3' },
            { 'version' => '1.2.4' }
          ],
          'RHEL-6.9' => [
            { 'version' => '0.1.2' }
          ]
        }
      )

      assert_equal SupportedSsg.by_ssg_version.keys, ['1.2.3', '1.2.4', '0.1.2']
    end
  end

  context '#ssg_versions_for_os' do
    should 'return true for OS/SSG matches' do
      SupportedSsg.stubs(:raw_supported).returns(
        'supported' => {
          'RHEL-7.4' => [
            { 'version' => '1.2.3' },
            { 'version' => '1.2.4' }
          ],
          'RHEL-6.9' => [
            { 'version' => '0.1.2' }
          ]
        }
      )

      assert_includes SupportedSsg.ssg_versions_for_os(7, 4), '1.2.4'
      assert_includes SupportedSsg.ssg_versions_for_os(7, 4), '1.2.3'
      assert_includes SupportedSsg.ssg_versions_for_os(6, 9), '0.1.2'
      assert_equal SupportedSsg.ssg_versions_for_os(8, 1), []
    end
  end
end
