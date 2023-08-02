# frozen_string_literal: true

require 'test_helper'

class CreateBusinessObjectiveMutationTest < ActiveSupport::TestCase
  setup do
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  QUERY = <<-GRAPHQL
     mutation createBusinessObjective($input: createBusinessObjectiveInput!) {
        createBusinessObjective(input: $input) {
           businessObjective {
               id
               title
           }
        }
     }
  GRAPHQL

  test 'create business objective' do
    user = FactoryBot.create(:user)

    assert_audited_success 'Created Business Objective'
    result = Schema.execute(
      QUERY,
      variables: { input: {
        title: 'foobar'
      } },
      context: { current_user: user }
    )['data']['createBusinessObjective']['businessObjective']

    assert_equal result['title'], 'foobar'
  end

  test 'does not duplicate business objectives' do
    bo = FactoryBot.create(:business_objective)
    user = FactoryBot.create(:user)

    assert_audited_success 'Created Business Objective'
    result = Schema.execute(
      QUERY,
      variables: { input: {
        title: bo.title
      } },
      context: { current_user: user }
    )['data']['createBusinessObjective']['businessObjective']

    assert_equal result['id'], bo.id
    assert_equal result['title'], bo.title
  end
end
