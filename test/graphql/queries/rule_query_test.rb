# frozen_string_literal: true

require 'test_helper'

class RuleQueryTest < ActiveSupport::TestCase
  setup do
    users(:test).update account: accounts(:test)
    profiles(:one).update(account: accounts(:test), hosts: [hosts(:one)])
    profiles(:one).update rules: [rules(:one)]
    rules(:one).update rule_identifier: rule_identifiers(:one)
    rules(:one).update rule_references: [rule_references(:one)]
    rule_results(:one).update(
      host: hosts(:one), rule: rules(:one), test_result: test_results(:one)
    )
    test_results(:one).update(profile: profiles(:one), host: hosts(:one))
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
        id: profiles(:one).id,
        systemId: hosts(:one).id
      },
      context: { current_user: users(:test) }
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
        id: profiles(:one).id,
        identifier: rule_identifiers(:one).label
      },
      context: { current_user: users(:test) }
    )
    assert_not result.dig('errors'),
               "Query was unsuccessful: #{result.dig('errors')}"
    assert result.dig('data', 'profile', 'rules').any?, 'No rules returned!'
    assert_equal rule_identifiers(:one).label,
                 result.dig('data', 'profile', 'rules',
                            0, 'identifier')
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
        id: profiles(:one).id,
        references: [rule_references(:one).label]
      },
      context: { current_user: users(:test) }
    )
    assert_not result.dig('errors'),
               "Query was unsuccessful: #{result.dig('errors')}"
    assert result.dig('data', 'profile', 'rules').any?, 'No rules returned!'
    assert_equal [[rule_references(:one).href,
                   rule_references(:one).label]].to_json,
                 result.dig('data', 'profile', 'rules',
                            0, 'references')
  end
end
