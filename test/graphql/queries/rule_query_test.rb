# frozen_string_literal: true

require 'test_helper'

class RuleQueryTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @host = FactoryBot.create(:host, account: @user.account.account_number)
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
    @rr = FactoryBot.create(:rule_reference)
    @ri = FactoryBot.create(:rule_identifier, rule: rule)
    @profile.rules.first.update!(
      rule_references: [@rr]
    )
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
        identifier: @ri.label
      },
      context: { current_user: @user }
    )
    assert_not result.dig('errors'),
               "Query was unsuccessful: #{result.dig('errors')}"
    assert result.dig('data', 'profile', 'rules').any?, 'No rules returned!'
    assert_equal(
      { label: @ri.label,
        system: @ri.system }.to_json,
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
        references: [@rr.label]
      },
      context: { current_user: @user }
    )
    assert_not result.dig('errors'),
               "Query was unsuccessful: #{result.dig('errors')}"
    assert result.dig('data', 'profile', 'rules').any?, 'No rules returned!'
    assert_equal [{ href: @rr.href,
                    label: @rr.label }].to_json,
                 result.dig('data', 'profile', 'rules',
                            0, 'references')
  end
end
