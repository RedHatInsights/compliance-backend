# frozen_string_literal: true

require 'swagger_helper'

describe 'RuleResults API', swagger_doc: 'v1/openapi.json' do
  before do
    @account = FactoryBot.create(:account)
    host = FactoryBot.create(:host, org_id: @account.org_id)
    profile = FactoryBot.create(
      :profile,
      :with_rules,
      account: @account,
      rule_count: 1
    )
    tr = FactoryBot.create(:test_result, profile: profile, host: host)
    FactoryBot.create(
      :rule_result,
      test_result: tr,
      host: host,
      rule: profile.rules.first
    )
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
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
      sort_params(RuleResult)

      include_param

      response '200', 'lists all rule_results requested' do
        let(:'X-RH-IDENTITY') { encoded_header(@account) }
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
