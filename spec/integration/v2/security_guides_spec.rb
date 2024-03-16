# frozen_string_literal: true

require 'swagger_helper'

describe 'Security Guides', swagger_doc: 'v2/openapi.json' do
  let(:'X-RH-IDENTITY') { FactoryBot.create(:v2_user).account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/security_guides' do
    before { FactoryBot.create_list(:v2_security_guide, 25) }

    get 'Request Security Guides' do
      v2_auth_header
      tags 'Content'
      description 'Lists Security Guides'
      operationId 'SecurityGuides'
      content_types
      pagination_params_v2
      sort_params_v2(V2::SecurityGuide)
      search_params_v2(V2::SecurityGuide)

      response '200', 'Lists Security Guides' do
        v2_collection_schema 'security_guide'

        after { |e| autogenerate_examples(e, 'List of Security Guides') }

        run_test!
      end

      response '200', 'Lists Security Guides' do
        let(:sort_by) { ['os_major_version'] }
        v2_collection_schema 'security_guide'

        after { |e| autogenerate_examples(e, 'List of Security Guides sorted by "os_major_verision:asc"') }

        run_test!
      end

      response '200', 'Lists Security Guides' do
        let(:filter) { '(os_major_version=8)' }
        v2_collection_schema 'security_guide'

        after { |e| autogenerate_examples(e, 'List of Security Guides filtered by "(os_major_version=8)"') }

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

  path '/security_guides/{id}' do
    let(:item) { FactoryBot.create(:v2_security_guide) }

    get 'Request a Security Guide' do
      v2_auth_header
      tags 'Content'
      description 'Returns a Security Guide'
      operationId 'SecurityGuide'
      content_types

      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Security Guide' do
        let(:id) { item.id }
        v2_item_schema('security_guide')

        after { |e| autogenerate_examples(e, 'Returns a Security Guide') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing Security Guide') }

        run_test!
      end
    end
  end
end
