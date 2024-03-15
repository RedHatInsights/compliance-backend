# frozen_string_literal: true

require 'swagger_helper'

describe 'Profiles', swagger_doc: 'v2/openapi.json' do
  let(:'X-RH-IDENTITY') { FactoryBot.create(:v2_user).account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/security_guides/{security_guide_id}/profiles' do
    before { FactoryBot.create_list(:v2_profile, 25, security_guide_id: security_guide_id) }

    let(:security_guide_id) { FactoryBot.create(:v2_security_guide).id }

    get 'Request Profiles' do
      v2_auth_header
      tags 'profiles'
      description 'Lists Profiles'
      operationId 'Profiles'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Profile)
      search_params_v2(V2::Profile)

      parameter name: :security_guide_id, in: :path, type: :string, required: true

      response '200', 'Lists Profiles' do
        v2_collection_schema 'profile'

        after { |e| autogenerate_examples(e, 'List of Profiles') }

        run_test!
      end

      response '200', 'Lists Profiles' do
        let(:sort_by) { ['title'] }
        v2_collection_schema 'profile'

        after { |e| autogenerate_examples(e, 'List of Profiles sorted by "title:asc"') }

        run_test!
      end

      response '200', 'Lists Profiles' do
        let(:filter) { "(title=#{V2::Profile.first.title})" }
        v2_collection_schema 'profile'

        after { |e| autogenerate_examples(e, "List of Profiles filtered by '(title=#{V2::Profile.first.title})'") }

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

  path '/security_guides/{security_guide_id}/profiles/{id}' do
    let(:item) { FactoryBot.create(:v2_profile) }

    get 'Request a Profile' do
      v2_auth_header
      tags 'profiles'
      description 'Returns a Profile'
      operationId 'Profile'
      content_types

      parameter name: :security_guide_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Profile' do
        let(:id) { item.id }
        let(:security_guide_id) { item.security_guide.id }
        v2_item_schema('profile')

        after { |e| autogenerate_examples(e, 'Returns a Profile') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:id) { Faker::Internet.uuid }
        let(:security_guide_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing Profile') }

        run_test!
      end
    end
  end
end
