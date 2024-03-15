# frozen_string_literal: true

require 'swagger_helper'

describe 'Value Definitions', swagger_doc: 'v2/openapi.json' do
  let(:'X-RH-IDENTITY') { FactoryBot.create(:v2_user).account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/security_guides/{security_guide_id}/value_definitions' do
    before { FactoryBot.create_list(:v2_value_definition, 25, security_guide_id: security_guide_id) }

    let(:security_guide_id) { FactoryBot.create(:v2_security_guide).id }

    get 'Request Value Definitions' do
      v2_auth_header
      tags 'value_definitions'
      description 'Lists Value Definitions'
      operationId 'Value Definitions'
      content_types
      pagination_params_v2
      sort_params_v2(V2::ValueDefinition)
      search_params_v2(V2::ValueDefinition)

      parameter name: :security_guide_id, in: :path, type: :string, required: true

      response '200', 'Lists Value Definitions' do
        v2_collection_schema 'value_definition'

        after { |e| autogenerate_examples(e, 'List of Value Definitions') }

        run_test!
      end

      response '200', 'Lists Value Definitions' do
        let(:sort_by) { ['title'] }
        v2_collection_schema 'value_definition'

        after { |e| autogenerate_examples(e, 'List of Value Definitions sorted by "title:asc"') }

        run_test!
      end

      response '200', 'Lists Value Definitions' do
        let(:filter) { "(title=#{V2::ValueDefinition.first.title})" }
        v2_collection_schema 'value_definition'

        after do |e|
          autogenerate_examples(e, "List of Value Definitions filtered by '(title=#{V2::ValueDefinition.first.title})'")
        end

        run_test!
      end

      response '422', 'Returns with Unprocessable Content' do
        let(:sort_by) { ['description'] }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when sorting by incorrect parameter') }

        run_test!
      end

      response '422', 'Returns with Unprocessable Content' do
        let(:limit) { 103 }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting higher limit than supported') }

        run_test!
      end
    end
  end

  path '/security_guides/{security_guide_id}/value_definitions/{id}' do
    let(:item) { FactoryBot.create(:v2_value_definition) }

    get 'Request a Value Definition' do
      v2_auth_header
      tags 'value_definitions'
      description 'Returns a Value Definition'
      operationId 'Value Definition'
      content_types

      parameter name: :security_guide_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Value Definition' do
        let(:id) { item.id }
        let(:security_guide_id) { item.security_guide.id }
        v2_item_schema('value_definition')

        after { |e| autogenerate_examples(e, 'Returns a Value Definition') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:id) { Faker::Internet.uuid }
        let(:security_guide_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after do |e|
          autogenerate_examples(e, 'Description of an error when requesting a non-existing Value Definition')
        end

        run_test!
      end
    end
  end
end
