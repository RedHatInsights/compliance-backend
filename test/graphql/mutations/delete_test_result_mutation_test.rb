# frozen_string_literal: true

require 'test_helper'

require 'sidekiq/testing'
Sidekiq::Testing.fake!

class DeleteTestResultMutationTest < ActiveSupport::TestCase
  QUERY = <<-GRAPHQL
      mutation deleteTestResults($input: deleteTestResultsInput!) {
          deleteTestResults(input: $input) {
              profile {
                  id
              }
              testResults {
                  id
              }
          }
      }
  GRAPHQL

  setup do
    users(:test).update! account: accounts(:test)
    profiles(:one).update! account: accounts(:test), hosts: [hosts(:one)]
    hosts(:one).update! account: accounts(:test)
    test_results(:one).update! host: hosts(:one), profile: profiles(:one)
  end

  test 'delete a test result keeps the profile if not-external' do
    profiles(:one).update(policy_object: policies(:one))
    assert_difference('TestResult.count', -1) do
      assert_difference('Profile.count', 0) do
        assert_difference('ProfileHost.count', 0) do
          result = Schema.execute(
            QUERY,
            variables: { input: {
              profileId: profiles(:one).id
            } },
            context: { current_user: users(:test) }
          ).dig('data', 'deleteTestResults')
          assert_equal profiles(:one).id, result.dig('profile', 'id')
          assert_equal test_results(:one).id, result.dig('testResults', 0, 'id')
        end
      end
    end
  end

  test 'deleting results for external policy removes profile and profilehost' do
    profiles(:one).update(policy_object: nil)
    assert_difference('TestResult.count', -1) do
      assert_difference('Profile.count', -1) do
        result = Schema.execute(
          QUERY,
          variables: { input: {
            profileId: profiles(:one).id
          } },
          context: { current_user: users(:test) }
        ).dig('data', 'deleteTestResults')
        assert_equal profiles(:one).id, result.dig('profile', 'id')
        assert_equal test_results(:one).id, result.dig('testResults', 0, 'id')
      end
    end
  end
end
