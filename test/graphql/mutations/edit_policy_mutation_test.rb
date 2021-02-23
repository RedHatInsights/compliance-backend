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
                          hosts: [hosts(:one)],
                          policy_object: policies(:one))
    assert_nil policies(:one).business_objective

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
    assert_audited 'Updated profile'
    assert_audited profiles(:one).id
    assert_audited policies(:one).id
  end

  test 'unset the business objective' do
    query = <<-GRAPHQL
        mutation updateProfile($input: UpdateProfileInput!) {
            updateProfile(input: $input) {
                profile {
                    businessObjectiveId
                }
            }
        }
    GRAPHQL

    users(:test).update account: accounts(:test)
    policies(:one).update!(business_objective: business_objectives(:one))
    profiles(:one).update(account: accounts(:test),
                          hosts: [hosts(:one)],
                          policy_object: policies(:one))

    Schema.execute(
      query,
      variables: { input: {
        id: profiles(:one).id,
        businessObjectiveId: nil
      } },
      context: { current_user: users(:test) }
    )['data']['updateProfile']['profile']

    assert_nil policies(:one).reload.business_objective
    assert_audited 'Updated profile'
    assert_audited profiles(:one).id
    assert_audited policies(:one).id
  end
end
