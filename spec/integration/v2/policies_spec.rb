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

        after { |e| autogenerate_examples(e, 'List of Policies sorted by "os_major_version:asc"') }

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
      operationId 'CreatePolicy'
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

  path '/policies/{policy_id}' do
    let(:item) { FactoryBot.create(:v2_policy, account: user.account) }

    get 'Request a Policy' do
      v2_auth_header
      tags 'Policies'
      description 'Returns a Policy'
      operationId 'Policy'
      content_types

      parameter name: :policy_id, in: :path, type: :string, required: true

      response '200', 'Returns a Policy' do
        let(:policy_id) { item.id }
        v2_item_schema('policy')

        after { |e| autogenerate_examples(e, 'Returns a Policy') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:policy_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing Policy') }

        run_test!
      end
    end

    patch 'Update a Policy' do
      v2_auth_header
      tags 'Policies'
      description 'Updates a Policy with the provided attributes'
      operationId 'UpdatePolicy'
      content_types

      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :data, in: :body, schema: ref_schema('policy_update')

      let(:data) { { compliance_threshold: 100 } }

      response '202', 'Updates a Policy' do
        let(:policy_id) { item.id }
        v2_item_schema('policy')

        after { |e| autogenerate_examples(e, 'Returns the updated Policy') }

        run_test!
      end
    end

    delete 'Delete a Policy' do
      v2_auth_header
      tags 'Policies'
      description 'Deletes a Policy'
      operationId 'DeletePolicy'
      content_types

      parameter name: :policy_id, in: :path, type: :string, required: true

      response '202', 'Deletes a Policy' do
        let(:policy_id) { item.id }
        v2_item_schema('policy')

        after { |e| autogenerate_examples(e, 'Deletes a Policy') }

        run_test!
      end
    end
  end

  path '/systems/{system_id}/policies' do
    let(:system_id) { FactoryBot.create(:system, account: user.account, os_major_version: 7, os_minor_version: 1).id }

    before do
      FactoryBot.create_list(
        :v2_policy,
        25,
        account: user.account,
        system_id: system_id,
        os_major_version: 7,
        supports_minors: [1]
      )
    end

    get 'Request Policies assigned to a System' do
      v2_auth_header
      tags 'Systems'
      description 'Lists Policies under a System'
      operationId 'SystemsPolicies'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Policy, except: %i[os_major_version total_system_count])
      search_params_v2(V2::Policy, except: %i[os_major_version])

      parameter name: :system_id, in: :path, type: :string, required: true

      response '200', 'Lists Policies' do
        v2_collection_schema 'policy'

        after { |e| autogenerate_examples(e, 'List of Policies under a System') }

        run_test!
      end
    end
  end
end
