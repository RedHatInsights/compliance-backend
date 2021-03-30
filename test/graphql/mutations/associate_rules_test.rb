# frozen_string_literal: true

require 'test_helper'

class AssociateRulesMutationTest < ActiveSupport::TestCase
  setup do
    profiles(:one).update account: accounts(:one),
                          policy: policies(:one)
    users(:test).update account: accounts(:one)
  end

  {
    ruleIds: :id,
    ruleRefIds: :ref_id
  }.each do |key, field|
    context key do
      should 'provide all required arguments' do
        query = <<-GRAPHQL
           mutation associateRules($input: associateRulesInput!) {
              associateRules(input: $input) {
                 profile {
                     id
                 }
              }
           }
        GRAPHQL

        assert_empty profiles(:one).rules

        Schema.execute(
          query,
          variables: { input: {
            id: profiles(:one).id,
            key => [rules(:one).send(field)]
          } },
          context: { current_user: users(:test) }
        )['data']['associateRules']['profile']

        assert_equal Set.new(profiles(:one).reload.rules),
                     Set.new([rules(:one)])
      end

      should 'removes rules from a profile' do
        query = <<-GRAPHQL
           mutation associateRules($input: associateRulesInput!) {
              associateRules(input: $input) {
                 profile {
                     id
                 }
              }
           }
        GRAPHQL

        profiles(:one).update!(rules: [profiles(:one).benchmark.rules.first])
        assert_not_empty profiles(:one).rules

        Schema.execute(
          query,
          variables: { input: {
            id: profiles(:one).id,
            key => []
          } },
          context: { current_user: users(:test) }
        )['data']['associateRules']['profile']

        assert_empty profiles(:one).reload.rules
        assert_audited 'Updated rule assignments of profile'
        assert_audited policies(:one).id
      end
    end
  end

  test 'fails if no rules are passed' do
    query = <<-GRAPHQL
       mutation associateRules($input: associateRulesInput!) {
          associateRules(input: $input) {
             profile {
                 id
             }
          }
       }
    GRAPHQL

    assert_raises ArgumentError do
      Schema.execute(
        query,
        variables: { input: {
          id: profiles(:one).id
        } },
        context: { current_user: users(:test) }
      )['data']['associateRules']['profile']
    end
  end
end
