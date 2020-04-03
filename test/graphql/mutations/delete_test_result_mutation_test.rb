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
    profiles(:one).update! account: accounts(:test)
    hosts(:one).update! account: accounts(:test)
    test_results(:one).update! host: hosts(:one), profile: profiles(:one)
  end

  test 'delete a test result provided a profile ID' do
    assert_difference('TestResult.count', -1) do
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
