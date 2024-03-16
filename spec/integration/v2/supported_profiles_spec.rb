# frozen_string_literal: true

require 'swagger_helper'

describe 'Supported Profiles', swagger_doc: 'v2/openapi.json' do
  let(:'X-RH-IDENTITY') { FactoryBot.create(:v2_user).account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/security_guides/supported_profiles' do
    before { FactoryBot.create(:v2_profile, supports_minors: [1, 2, 3]) }

    get 'Request Supported Profiles' do
      v2_auth_header
      tags 'Content'
      description 'Lists Supported Profiles'
      operationId 'SupportedProfiles'
      content_types
      pagination_params_v2
      sort_params_v2(V2::SupportedProfile)
      search_params_v2(V2::SupportedProfile)

      response '200', 'Lists Supported Profiles' do
        v2_collection_schema 'supported_profile'

        after { |e| autogenerate_examples(e, 'List of Supported Profiles') }

        run_test!
      end

      response '200', 'Lists Supported Profiles' do
        let(:sort_by) { ['os_major_version'] }
        v2_collection_schema 'supported_profile'

        after { |e| autogenerate_examples(e, 'List of Supported Profiles sorted by "os_major_verision:asc"') }

        run_test!
      end

      response '200', 'Lists Supported Profiles' do
        let(:filter) { '(os_major_version=8)' }
        v2_collection_schema 'supported_profile'

        after { |e| autogenerate_examples(e, 'List of Supported Profiles filtered by "(os_major_version=8)"') }

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
end
