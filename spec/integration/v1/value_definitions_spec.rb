# frozen_string_literal: true

require 'swagger_helper'
require 'sidekiq/testing'

describe 'ValueDefinitions API', swagger_doc: 'v1/openapi.json' do
  before do
    @account = FactoryBot.create(:account)
    FactoryBot.create_list(:value_definition, 2)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  path '/value_definitions' do
    get 'List all value definitions' do
      tags 'value_definition'
      description 'Lists all value definitions requested'
      operationId 'ListValueDefinitions'

      content_types
      auth_header
      pagination_params
      search_params

      include_param

      response '200', 'lists all value_definitions requested' do
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
                       attributes: ref_schema('value_definition'),
                       relationships: ref_schema('value_definition_relationships')
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
