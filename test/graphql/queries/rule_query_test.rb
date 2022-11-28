# frozen_string_literal: true

require 'test_helper'

class RuleQueryTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @host = FactoryBot.create(:host, org_id: @user.account.org_id)
    @profile = FactoryBot.create(
      :profile,
      :with_rules,
      rule_count: 1,
      account: @user.account
    )
    rule = @profile.rules.first

    tr = FactoryBot.create(:test_result, host: @host, profile: @profile)
    FactoryBot.create(
      :rule_result,
      host: @host,
      rule: rule,
      test_result: tr
    )
    @profile.rules.first.update!(
      references: [{ label: 'foo', href: 'bar' }]
    )

    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
  end

  test 'rules are filtered by system ID' do
    query = <<-GRAPHQL
      query Profile($id: String!, $systemId: String){
          profile(id: $id) {
              id
              name
              refId
              rules(systemId: $systemId) {
                id
              }
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: {
        id: @profile.id,
        systemId: @host.id
      },
      context: { current_user: @user }
    )
    assert_not result.dig('errors'),
               "Query was unsuccessful: #{result.dig('errors')}"
    assert result.dig('data', 'profile', 'rules').any?, 'No rules returned!'
  end

  test 'rules are filtered by identifier' do
    query = <<-GRAPHQL
      query Profile($id: String!, $identifier: String){
          profile(id: $id) {
              id
              name
              refId
              rules(identifier: $identifier) {
                id
                identifier
              }
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: {
        id: @profile.id,
        identifier: @profile.rules.first.identifier[:label]
      },
      context: { current_user: @user }
    )
    assert_not result.dig('errors'),
               "Query was unsuccessful: #{result.dig('errors')}"
    assert result.dig('data', 'profile', 'rules').any?, 'No rules returned!'
    assert_equal(
      { 'label' => @profile.rules.first.identifier['label'],
        'system' => @profile.rules.first.identifier['system'] },
      result.dig('data', 'profile', 'rules', 0, 'identifier')
    )
  end

  test 'rules are filtered by references' do
    query = <<-GRAPHQL
      query Profile($id: String!, $references: [String!]){
          profile(id: $id) {
              id
              name
              refId
              rules(references: $references) {
                id
                references
              }
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: {
        id: @profile.id,
        references: ['foo']
      },
      context: { current_user: @user }
    )
    assert_not result.dig('errors'),
               "Query was unsuccessful: #{result.dig('errors')}"
    assert result.dig('data', 'profile', 'rules').any?, 'No rules returned!'
    assert_equal [{ 'href' => 'bar',
                    'label' => 'foo' }],
                 result.dig('data', 'profile', 'rules',
                            0, 'references')
  end
end
