# frozen_string_literal: true

require 'test_helper'

class EditPolicyMutationTest < ActiveSupport::TestCase
  test 'query host owned by the user' do
    query = <<-GRAPHQL
        mutation updateProfile($input: UpdateProfileInput!) {
            updateProfile(input: $input) {
                profile {
                    id,
                    complianceThreshold,
                    businessObjectiveId
                }
            }
        }
    GRAPHQL

    users(:test).update account: accounts(:test)
    profiles(:one).update(account: accounts(:test),
                          compliance_threshold: 90,
                          business_objective: nil)

    result = Schema.execute(
      query,
      variables: { input: {
        id: profiles(:one).id,
        complianceThreshold: 80.0,
        businessObjectiveId: business_objectives(:one).id
      } },
      context: { current_user: users(:test) }
    )['data']['updateProfile']['profile']

    assert_equal business_objectives(:one).id, result['businessObjectiveId']
    assert_equal 80.0, result['complianceThreshold']
  end
end
