# frozen_string_literal: true

require 'test_helper'

class CreateProfileMutationTest < ActiveSupport::TestCase
  test 'provide all required arguments' do
    query = <<-GRAPHQL
       mutation createProfile($input: createProfileInput!) {
          createProfile(input: $input) {
             profile {
                 id
             }
          }
       }
    GRAPHQL

    original_profile = profiles(:one)
    original_profile.update account: accounts(:test)
    users(:test).update account: accounts(:test)

    result = Schema.execute(
      query,
      variables: { input: {
        benchmarkId: original_profile.benchmark_id,
        cloneFromProfileId: original_profile.id,
        refId: 'xccdf-customized',
        name: 'customized profile',
        description: 'abcdf',
        complianceThreshold: 90.0
      } },
      context: { current_user: users(:test) }
    )['data']['createProfile']['profile']

    cloned_profile = ::Profile.find(result['id'])
    assert cloned_profile.ref_id, 'xccdf-customized'
    assert_equal cloned_profile.rules, original_profile.rules
    assert_equal cloned_profile.parent_profile, original_profile
  end
end
