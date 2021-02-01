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

  test 'delete a test result keeps the profile if part of a policy' do
    profiles(:one).update(policy_object: policies(:one), external: true)
    assert_difference('TestResult.count', -1) do
      assert_difference('Profile.count', 0) do
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

  test 'delete test results from initial policy profile deletes all results'\
       'in the policy' do
    hosts(:two).update! account: accounts(:test)
    profiles(:one).update!(policy_object: policies(:one), external: false)
    profiles(:two).update!(policy_object: policies(:one), external: true,
                           account: accounts(:test))
    test_results(:two).update! host: hosts(:two), profile: profiles(:two)
    assert_difference('TestResult.count', -2) do
      assert_difference('Profile.count', 0) do
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

  test 'deleting results for external policy removes profile and profilehost' do
    profiles(:one).update(policy_object: nil, external: true)
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
