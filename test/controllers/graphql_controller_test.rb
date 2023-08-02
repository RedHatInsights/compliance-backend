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

  context 'authorized user' do
    setup do
      account = FactoryBot.create(:account)
      @current_user = FactoryBot.create(:user, account: account)
      stub_rbac_permissions(Rbac::COMPLIANCE_VIEWER, Rbac::INVENTORY_HOSTS_READ)
    end

    should 'be allowed to read inventory' do
      assert_equal @current_user.authorized_to?(Rbac::INVENTORY_HOSTS_READ), true
    end
  end

  context 'unauthorized user' do
    setup do
      account = FactoryBot.create(:account)
      @current_user = FactoryBot.create(:user, account: account)
      stub_rbac_permissions
    end

    should 'not be allowed to read inventory' do
      account = FactoryBot.create(:account)
      user = FactoryBot.create(:user, account: account)
      User.current = user
      identity = Base64.encode64(
        {
          identity: {
            org_id: account.org_id
          },
          entitlements: {
            insights: {
              is_entitled: true
            }
          }
        }.to_json
      )
      variables = ['samplevar']
      query = <<-GRAPHQL
        query Benchmarks {
            benchmarks {
                nodes {
                    id
                }
            }
        }
      GRAPHQL

      post(graphql_url, params: { variables: variables, query: query }, headers: { 'X-RH-IDENTITY': identity })
      assert_response :forbidden
    end
  end

  context 'user with insufficient permissions to inventory' do
    setup do
      @account = FactoryBot.create(:account)
      @current_user = FactoryBot.create(:user, account: @account)
      @host1 = FactoryBot.create(:host, org_id: @current_user.account.org_id)
      stub_rbac_permissions(Rbac::COMPLIANCE_VIEWER, 'inventory:groups:read')
    end

    should 'not be allowed to access hosts' do
      query = <<-GRAPHQL
        query System($inventoryId: String!){
            system(id: $inventoryId) {
                name
            }
        }
      GRAPHQL
      variables = {
        inventoryId: @host1.id
      }
      identity = Base64.encode64(
        {
          identity: {
            org_id: @account.org_id
          },
          entitlements: {
            insights: {
              is_entitled: true
            }
          }
        }.to_json
      )

      post(graphql_url, params: { variables: variables, query: query }, headers: { 'X-RH-IDENTITY': identity })
      assert_response :forbidden
    end
  end

  context 'unauthorized user' do
    setup do
      stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ)
    end

    should 'not be allowed to mutate objects' do
      account = FactoryBot.create(:account)
      user = FactoryBot.create(:user, account: account)
      User.current = user
      identity = Base64.encode64(
        {
          identity: {
            org_id: account.org_id
          },
          entitlements: {
            insights: {
              is_entitled: true
            }
          }
        }.to_json
      )
      variables = {
        input: {
          id: '20f8c538-bd04-4b4b-b96c-9cccf46a12a2',
          systemIds: ['223bcaa3-82d2-433f-909e-bfbf658d6c9c']
        }
      }
      query = <<-GRAPHQL
        mutation associateSystems($input: associateSystemsInput!) {
            associateSystems(input: $input) {
                profile {
                    id
                    policy {
                        id
                        profiles {
                            id
                            parentProfileId
                            osMinorVersion
                        }
                    }
                }
            }
          }
      GRAPHQL
      post(graphql_url, params: { variables: variables, query: query }, headers: { 'X-RH-IDENTITY': identity })
      assert_equal @response.parsed_body['errors'].first, 'You are not authorized to access this action.'
      assert_response :forbidden
    end
  end
end
