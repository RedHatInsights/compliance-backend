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
                supportedProfiles {
                  id
                }
              }
            }
          }
      }
    GRAPHQL

    user = FactoryBot.create(:user)
    p1 = FactoryBot.create(:canonical_profile)
    p2 = FactoryBot.create(:canonical_profile)
    p3 = FactoryBot.create(:canonical_profile, os_major_version: '8')

    SupportedSsg.expects(:by_os_major).times(2).returns(
      {
        '7' => [p1, p2].map do |p|
          OpenStruct.new(version: p.benchmark.version)
        end,
        '8' => [OpenStruct.new(version: p3.benchmark.version)]
      }
    )

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: user }
    )

    edges = result['data']['osMajorVersions']['edges']
    versions = edges.each_with_object({}) do |g, obj|
      major = g['node']['osMajorVersion']

      obj[major] = g['node']['supportedProfiles'].map do |p|
        p['id']
      end
    end

    assert_same_elements [7, 8], versions.keys
    assert_same_elements [p1.id, p2.id], versions[7]
    assert_equal [p3.id], versions[8]
  end
end
