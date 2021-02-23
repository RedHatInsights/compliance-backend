# frozen_string_literal: true

require 'swagger_helper'

describe 'RuleResults API' do
  fixtures :accounts, :rules, :rule_results

  before do
    rule_results(:one).update(host: hosts(:one), rule: rules(:one))
  end

  path '/rule_results' do
    get 'List all rule_results' do
      tags 'rule_result'
      description 'Lists all rule_results requested'
      operationId 'ListRuleResults'

      content_types
      auth_header
      pagination_params
      search_params

      include_param

      response '200', 'lists all rule_results requested' do
        let(:'X-RH-IDENTITY') { encoded_header(accounts(:one)) }
        let(:include) { '' } # work around buggy rswag
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: { type: :string, format: :uuid },
                       attributes: ref_schema('rule_result'),
                       relationships: ref_schema('rule_result_relationships')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end
end
