# frozen_string_literal: true

require 'test_helper'

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  test 'calls the schema executor with a query, variables, and user' do
    GraphqlController.any_instance.expects(:authenticate_user).yields
    query = 'gqlquery'
    variables = ['samplevar']
    User.current = users(:test)
    Schema.expects(:execute).with(
      query, variables: variables, context: { current_user: users(:test) }
    )
    post graphql_url, params: { variables: variables, query: query }
    assert_response :success
  end
end
