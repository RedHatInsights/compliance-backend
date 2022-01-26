# frozen_string_literal: true

require 'test_helper'

class OsMajorVersionQueryTest < ActiveSupport::TestCase
  test 'query for OS major versions and supported profiles' do
    query = <<-GRAPHQL
      {
          osMajorVersions {
            edges {
              node {
                osMajorVersion
                profiles {
                  id
                  supportedOsVersions
                }
              }
            }
          }
      }
    GRAPHQL

    user = FactoryBot.create(:user)
    bm = FactoryBot.create(:benchmark)
    p1 = FactoryBot.create(:canonical_profile, upstream: false, benchmark: bm)
    p2 = FactoryBot.create(:canonical_profile, upstream: false, benchmark: bm)
    p3 = FactoryBot.create(:canonical_profile, os_major_version: '8', upstream: false)

    SupportedSsg.expects(:by_ssg_version).times(3).returns(
      {
        bm.version => [
          OpenStruct.new(version: bm.version, os_minor_version: '1', os_major_version: '7'),
          OpenStruct.new(version: bm.version, os_minor_version: '2', os_major_version: '7'),
          OpenStruct.new(version: bm.version, os_minor_version: '1', os_major_version: '8')
        ],
        p3.benchmark.version => [
          OpenStruct.new(version: p3.benchmark.version, os_minor_version: '2', os_major_version: '8')
        ]
      }
    )

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: user }
    )

    edges = result['data']['osMajorVersions']['edges']
    major_versions = edges.each_with_object({}) do |g, obj|
      major = g['node']['osMajorVersion']

      obj[major] = g['node']['profiles'].map do |p|
        p['id']
      end
    end

    minor_versions = edges.each_with_object({}) do |g, obj|
      g['node']['profiles'].map do |p|
        obj[p['id']] = p['supportedOsVersions']
      end
    end

    assert_same_elements [7, 8], major_versions.keys
    assert_same_elements [p1.id, p2.id], major_versions[7]
    assert_equal [p3.id], major_versions[8]

    assert_equal minor_versions[p1.id], ['7.2', '7.1']
    assert_equal minor_versions[p2.id], ['7.2', '7.1']
    assert_equal minor_versions[p3.id], ['8.2']
  end
end
