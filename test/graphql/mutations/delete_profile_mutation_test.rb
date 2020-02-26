# frozen_string_literal: true

require 'test_helper'

require 'sidekiq/testing'
Sidekiq::Testing.fake!

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
    assert_no_difference('DeleteTestResultsJob.jobs.size') do
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
    assert_difference('DeleteTestResultsJob.jobs.size', 1) do
      Schema.execute(
        QUERY,
        variables: { input: {
          id: profiles(:one).id,
          deleteAllTestResults: true
        } },
        context: { current_user: users(:test) }
      )
    end
  end
end
