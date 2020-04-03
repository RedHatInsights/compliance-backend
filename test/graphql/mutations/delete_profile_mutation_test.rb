# frozen_string_literal: true

require 'test_helper'

class DeleteProfileMutationTest < ActiveSupport::TestCase
  test 'delete a profile provided an ID' do
    query = <<-GRAPHQL
        mutation DeleteProfile($input: deleteProfileInput!) {
            deleteProfile(input: $input) {
                profile {
                    id
                }
            }
        }
    GRAPHQL

    users(:test).update account: accounts(:test)
    profiles(:one).update(account: accounts(:test))

    assert_difference('Profile.count', -1) do
      result = Schema.execute(
        query,
        variables: { input: {
          id: profiles(:one).id
        } },
        context: { current_user: users(:test) }
      )['data']['deleteProfile']['profile']
      assert_equal profiles(:one).id, result['id']
    end
  end
end
