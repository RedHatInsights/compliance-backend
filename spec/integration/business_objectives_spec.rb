# frozen_string_literal: true

require 'swagger_helper'

describe 'Business Objectives API', swagger_doc: 'v1/openapi.json' do
  before do
    @account = FactoryBot.create(:account)
    profiles = FactoryBot.create_list(
      :profile,
      2,
      account: @account
    )
    @bos = profiles.map do |profile|
      bo = FactoryBot.create(:business_objective)
      profile.policy.update!(business_objective: bo)
      bo
    end
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  path '/business_objectives' do
    get 'List all business_objectives' do
      tags 'business_objective'
      description 'Lists all business_objectives requested'
      operationId 'ListBusinessObjectives'

      content_types
      auth_header
      pagination_params
      search_params
      sort_params(BusinessObjective)

      include_param

      response '200', 'lists all business_objectives requested' do
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
                       id: ref_schema('uuid'),
                       attributes: ref_schema('business_objective')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end

  path '/business_objectives/{id}' do
    get 'Retrieve a business_objective' do
      tags 'business_objective'
      description 'Retrieves data for a business_objective'
      operationId 'ShowBusinessObjective'

      content_types
      auth_header

      parameter name: :id, in: :path, type: :string
      include_param

      response '404', 'business_objective not found' do
        let(:id) { 'invalid' }
        let(:'X-RH-IDENTITY') { encoded_header(@account) }
        let(:include) { '' } # work around buggy rswag

        after { |e| autogenerate_examples(e) }

        run_test!
      end

      response '200', 'retrieves a business_objective' do
        let(:'X-RH-IDENTITY') { encoded_header(@account) }
        let(:id) { @bos.first.id }
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
                     attributes: ref_schema('business_objective'),
                     relationships: ref_schema(
                       'business_objective_relationships'
                     )
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end
end
