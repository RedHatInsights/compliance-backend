# frozen_string_literal: true

require 'test_helper'

class DeleteProfileMutationTest < ActiveSupport::TestCase
  QUERY = <<-GRAPHQL
      mutation DeleteProfile($input: deleteProfileInput!) {
          deleteProfile(input: $input) {
              profile {
                  id
              }
          }
      }
  GRAPHQL

  setup do
    users(:test).update account: accounts(:test)
    profiles(:one).update(account: accounts(:test))
    test_results(:one).update(profile: profiles(:one), host: hosts(:one)).save
  end

  test 'delete a profile provided an ID' do
    assert_difference('Profile.count', -1) do
      result = Schema.execute(
        QUERY,
        variables: { input: {
          id: profiles(:one).id
        } },
        context: { current_user: users(:test) }
      )['data']['deleteProfile']['profile']
      assert_equal profiles(:one).id, result['id']
    end
  end

  test 'delete a profile provided an ID but not its test_results' do
    assert_no_difference('TestResult.count') do
      Schema.execute(
        QUERY,
        variables: { input: {
          id: profiles(:one).id
        } },
        context: { current_user: users(:test) }
      )
    end
  end

  test 'delete a profile and test_results when deleteAllTestResults is set' do
    assert_difference('TestResult.count', -1) do
      Schema.execute(
        QUERY,
        variables: { input: {
          id: profiles(:one).id,
          delete_all_test_results: true,
          deleteAllTestResults: true
        } },
        context: { current_user: users(:test) }
      )
    end
  end
end
