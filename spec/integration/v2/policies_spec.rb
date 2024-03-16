# frozen_string_literal: true

require 'swagger_helper'

describe 'Policies', swagger_doc: 'v2/openapi.json' do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:'X-RH-IDENTITY') { user.account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/policies' do
    before { FactoryBot.create_list(:v2_policy, 25, account: user.account) }

    get 'Request Policies' do
      v2_auth_header
      tags 'Policies'
      description 'Lists Policies'
      operationId 'Policies'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Policy)
      search_params_v2(V2::Policy)

      response '200', 'Lists Policies' do
        v2_collection_schema 'policy'

        after { |e| autogenerate_examples(e, 'List of Policies') }

        run_test!
      end

      response '200', 'Lists Policies' do
        let(:sort_by) { ['os_major_version'] }
        v2_collection_schema 'policy'

        after { |e| autogenerate_examples(e, 'List of Policies sorted by "os_major_verision:asc"') }

        run_test!
      end

      response '200', 'Lists Policies' do
        let(:filter) { '(os_major_version=8)' }
        v2_collection_schema 'policy'

        after { |e| autogenerate_examples(e, 'List of Policies filtered by "(os_major_version=8)"') }

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

    post 'Create a Policy' do
      v2_auth_header
      tags 'Policies'
      description 'Create a Policy with the provided attributes'
      operationId 'createPolicy'
      content_types

      parameter name: :data, in: :body, schema: ref_schema('policy')

      response '201', 'Creates a Policy' do
        let(:data) do
          {
            title: 'Foo',
            profile_id: FactoryBot.create(:v2_profile).id,
            compliance_threshold: 33.3,
            description: 'Hello World',
            business_objective: 'Serious Business Objective'
          }
        end

        v2_item_schema('policy')

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end

  path '/policies/{id}' do
    let(:item) { FactoryBot.create(:v2_policy, account: user.account) }

    get 'Request a Policy' do
      v2_auth_header
      tags 'Policies'
      description 'Returns a Policy'
      operationId 'Policy'
      content_types

      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Policy' do
        let(:id) { item.id }
        v2_item_schema('policy')

        after { |e| autogenerate_examples(e, 'Returns a Policy') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing Policy') }

        run_test!
      end
    end

    patch 'Update a Policy' do
      v2_auth_header
      tags 'Policies'
      description 'Updates a Policy with the provided attributes'
      operationId 'updatePolicy'
      content_types

      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :data, in: :body, schema: ref_schema('policy_update')

      let(:data) { { compliance_threshold: 100 } }

      response '202', 'Updates a Policy' do
        let(:id) { item.id }
        v2_item_schema('policy')

        after { |e| autogenerate_examples(e, 'Returns the updated Policy') }

        run_test!
      end
    end

    delete 'Delete a Policy' do
      v2_auth_header
      tags 'Policies'
      description 'Deletes a Policy'
      operationId 'deletePolicy'
      content_types

      parameter name: :id, in: :path, type: :string, required: true

      response '202', 'Deletes a Policy' do
        let(:id) { item.id }
        v2_item_schema('policy')

        after { |e| autogenerate_examples(e, 'Deletes a Policy') }

        run_test!
      end
    end
  end
end
