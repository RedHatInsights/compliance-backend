# frozen_string_literal: true

require 'swagger_helper'

describe 'Rules API' do
  before do
    @account = FactoryBot.create(:account)
    @profile = FactoryBot.create(
      :profile,
      :with_rules,
      rule_count: 1,
      account: @account
    )
    @profile.rules.update(precedence: 1)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
  end

  path "#{Settings.path_prefix}/#{Settings.app_name}/rules" do
    get 'List all rules' do
      tags 'rule'
      description 'Lists all rules requested'
      operationId 'ListRules'

      content_types
      auth_header
      pagination_params
      search_params
      sort_params(Rule)

      include_param

      response '200', 'lists all rules requested' do
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
                       attributes: ref_schema('rule'),
                       relationships: ref_schema('rule_relationships')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end

  path "#{Settings.path_prefix}/#{Settings.app_name}/rules/{id}" do
    get 'Retrieve a rule' do
      tags 'rule'
      description 'Retrieves data for a rule'
      operationId 'ShowRule'

      content_types
      auth_header

      parameter name: :id, in: :path, type: :string
      include_param

      response '404', 'rule not found' do
        let(:id) { FactoryBot.create(:rule).id }
        let(:'X-RH-IDENTITY') { encoded_header(@account) }
        let(:include) { '' } # work around buggy rswag

        after { |e| autogenerate_examples(e) }

        run_test!
      end

      response '200', 'retrieves a rule' do
        let(:'X-RH-IDENTITY') { encoded_header(@account) }
        let(:id) { @profile.rules.first.id }
        let(:include) { '' } # work around buggy rswag
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('uuid'),
                     attributes: ref_schema('rule'),
                     relationships: ref_schema('rule_relationships')
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end
end
