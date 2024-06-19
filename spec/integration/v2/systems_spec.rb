# frozen_string_literal: true

require 'swagger_helper'

describe 'Systems', swagger_doc: 'v2/openapi.json' do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:'X-RH-IDENTITY') { user.account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/systems' do
    before { FactoryBot.create_list(:system, 25, account: user.account) }

    get 'Request Systems' do
      v2_auth_header
      tags 'Systems'
      description 'Lists Systems'
      operationId 'Systems'
      content_types
      pagination_params_v2
      sort_params_v2(V2::System)
      search_params_v2(V2::System)

      response '200', 'Lists Systems' do
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems') }

        run_test!
      end

      response '200', 'Lists Systems' do
        let(:sort_by) { ['os_major_version'] }
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems sorted by "os_major_version:asc"') }

        run_test!
      end

      response '200', 'Lists Systems' do
        let(:filter) { '(os_major_version=8)' }
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems filtered by "(os_major_version=8)"') }

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

  path '/systems/{system_id}' do
    let(:item) { FactoryBot.create(:system, account: user.account) }

    get 'Request a System' do
      v2_auth_header
      tags 'Systems'
      description 'Returns a System'
      operationId 'System'
      content_types

      parameter name: :system_id, in: :path, type: :string, required: true

      response '200', 'Returns a System' do
        let(:system_id) { item.id }
        v2_item_schema('system')

        after { |e| autogenerate_examples(e, 'Returns a System') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:system_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing System') }

        run_test!
      end
    end
  end

  path '/policies/{policy_id}/systems' do
    before do
      FactoryBot.create_list(
        :system,
        25,
        policy_id: policy_id,
        os_major_version: 8,
        os_minor_version: 0,
        account: user.account
      )
    end

    let(:policy_id) do
      FactoryBot.create(
        :v2_policy,
        account: user.account,
        os_major_version: 8,
        supports_minors: [0]
      ).id
    end

    get 'Request Systems assigned to a Policy' do
      v2_auth_header
      tags 'Policies'
      description 'Lists Systems assigned to a Policy'
      operationId 'PolicySystems'
      content_types
      pagination_params_v2
      sort_params_v2(V2::System)
      search_params_v2(V2::System)

      parameter name: :policy_id, in: :path, type: :string, required: true

      response '200', 'Lists Systems' do
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems') }

        run_test!
      end

      response '200', 'Lists Systems assigned to a Policy' do
        let(:sort_by) { ['os_major_version'] }
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems sorted by "os_major_version:asc"') }

        run_test!
      end

      response '200', 'Lists Systems assigned to a Policy' do
        let(:filter) { '(os_major_version=8)' }
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems filtered by "(os_major_version=8)"') }

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

    post 'Bulk assign Systems to a Policy' do
      let(:items) do
        FactoryBot.create_list(
          :system,
          25,
          os_major_version: 8,
          os_minor_version: 0,
          account: user.account
        )
      end

      let(:data) { { ids: items.map(&:id) } }

      v2_auth_header
      tags 'Policies'
      description 'This feature is exclusively used by the frontend'
      deprecated true
      operationId 'AssignSystems'
      content_types

      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :data, in: :body, schema: {
        type: :object, properties: { ids: { type: :array, items: { type: :string, examples: [Faker::Internet.uuid] } } }
      }

      response '202', 'Assigns all specified systems and unassigns the rest' do
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of assigned Systems') }

        run_test!
      end
    end
  end

  path '/policies/{policy_id}/systems/{system_id}' do
    let(:policy_id) do
      FactoryBot.create(
        :v2_policy,
        account: user.account,
        os_major_version: 8,
        supports_minors: [0]
      ).id
    end

    patch 'Assign a System to a Policy' do
      let(:item) do
        FactoryBot.create(:system, account: user.account, os_major_version: 8, os_minor_version: 0)
      end

      v2_auth_header
      tags 'Policies'
      description 'Assigns a System to a Policy'
      operationId 'AssignSystem'
      content_types

      parameter name: :system_id, in: :path, type: :string, required: true
      parameter name: :policy_id, in: :path, type: :string, required: true

      response '202', 'Assigns a System to a Policy' do
        let(:system_id) { item.id }
        v2_item_schema('system')

        after { |e| autogenerate_examples(e, 'Assigns a System to a Policy') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:system_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Assigns a System to a Policy') }

        run_test!
      end
    end

    delete 'Unassign a System from a Policy' do
      let(:item) do
        FactoryBot.create(
          :system,
          account: user.account,
          os_major_version: 8,
          os_minor_version: 0,
          policy_id: policy_id
        )
      end

      v2_auth_header
      tags 'Policies'
      description 'Unassigns a System from a Policy'
      operationId 'UnassignSystem'
      content_types

      parameter name: :system_id, in: :path, type: :string, required: true
      parameter name: :policy_id, in: :path, type: :string, required: true

      response '202', 'Unassigns a System from a Policy' do
        let(:system_id) { item.id }
        v2_item_schema('system')

        after { |e| autogenerate_examples(e, 'Unassigns a System from a Policy') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:system_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when unassigning a non-existing System') }

        run_test!
      end
    end
  end

  path '/reports/{report_id}/systems' do
    before do
      FactoryBot.create_list(
        :system,
        25,
        policy_id: report_id,
        os_major_version: 8,
        os_minor_version: 0,
        account: user.account
      )
    end

    let(:report_id) do
      FactoryBot.create(
        :v2_report,
        account: user.account,
        os_major_version: 8,
        supports_minors: [0],
        assigned_system_count: 0
      ).id
    end

    get 'Request Systems assigned to a Report' do
      v2_auth_header
      tags 'Reports'
      description 'Lists Systems assigned to a Report'
      operationId 'ReportSystems'
      content_types
      pagination_params_v2
      sort_params_v2(V2::System)
      search_params_v2(V2::System)

      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Lists Systems' do
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems') }

        run_test!
      end

      response '200', 'Lists Systems assigned to a Report' do
        let(:sort_by) { ['os_major_version'] }
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems sorted by "os_major_version:asc"') }

        run_test!
      end

      response '200', 'Lists Systems assigned to a Report' do
        let(:filter) { '(os_major_version=8)' }
        v2_collection_schema 'system'

        after { |e| autogenerate_examples(e, 'List of Systems filtered by "(os_major_version=8)"') }

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

  path '/reports/{report_id}/systems/{system_id}' do
    let(:report_id) do
      FactoryBot.create(
        :v2_report,
        account: user.account,
        os_major_version: 8,
        supports_minors: [0],
        assigned_system_count: 0
      ).id
    end

    let(:item) { FactoryBot.create(:system, account: user.account, policy_id: report_id) }

    get 'Request a System' do
      v2_auth_header
      tags 'Reports'
      description 'Returns a System under a Report'
      operationId 'ReportSystem'
      content_types

      parameter name: :system_id, in: :path, type: :string, required: true
      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Returns a System under a Report' do
        let(:system_id) { item.id }
        v2_item_schema('system')

        after { |e| autogenerate_examples(e, 'Returns a System under a Report') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:system_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing System') }

        run_test!
      end
    end
  end
end
