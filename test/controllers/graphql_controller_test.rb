# frozen_string_literal: true

require 'test_helper'

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  test 'calls the schema executor with a query, variables, and user' do
    GraphqlController.any_instance.expects(:authenticate_user).yields
    query = 'gqlquery'
    variables = ['samplevar']
    user = FactoryBot.create(:user)
    User.current = user
    Schema.expects(:execute).with(
      query, variables: variables, context: { current_user: user }
    )
    post graphql_url, params: { variables: variables, query: query }
    assert_response :success
  end
end
