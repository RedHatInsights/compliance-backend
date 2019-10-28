# frozen_string_literal: true

require 'test_helper'

class AssociateSystemsMutationTest < ActiveSupport::TestCase
  test 'provide all required arguments' do
    query = <<-GRAPHQL
       mutation associateSystems($input: associateSystemsInput!) {
          associateSystems(input: $input) {
             profile {
                 id
             }
          }
       }
    GRAPHQL

    profiles(:one).update account: accounts(:test)
    hosts(:one).update account: accounts(:test)
    hosts(:two).update account: accounts(:test)
    users(:test).update account: accounts(:test)

    assert_empty profiles(:one).hosts

    Schema.execute(
      query,
      variables: { input: {
        id: profiles(:one).id,
        systemIds: [hosts(:one).id, hosts(:two).id]
      } },
      context: { current_user: users(:test) }
    )['data']['associateSystems']['profile']

    assert_equal profiles(:one).reload.hosts, [hosts(:one), hosts(:two)]
  end
end
