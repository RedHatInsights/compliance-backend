# frozen_string_literal: true

require 'swagger_helper'

describe 'Reports', swagger_doc: 'v2/openapi.json' do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:'X-RH-IDENTITY') { user.account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ, Rbac::REPORT_READ) }

  path '/reports' do
    before do
      FactoryBot.create_list(
        :v2_report, 5,
        os_major_version: 8,
        supports_minors: [0, 1, 2, 3, 4],
        account: user.account
      )
    end

    get 'Request Reports' do
      v2_auth_header
      tags 'Reports'
      description 'Lists Reports'
      operationId 'Reports'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Report)
      search_params_v2(V2::Report)

      response '200', 'Lists Reports' do
        v2_collection_schema 'report'

        after { |e| autogenerate_examples(e, 'List of Reports') }

        run_test!
      end

      response '200', 'Lists Reports' do
        let(:sort_by) { ['os_major_version'] }
        v2_collection_schema 'report'

        after { |e| autogenerate_examples(e, 'List of Reports sorted by "os_major_version:asc"') }

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

  path '/reports/{report_id}' do
    let(:item) do
      FactoryBot.create(
        :v2_report,
        os_major_version: 9,
        supports_minors: [0, 1, 2],
        account: user.account
      )
    end

    get 'Request a Report' do
      v2_auth_header
      tags 'Reports'
      description 'Returns a Report'
      operationId 'Report'
      content_types

      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Returns a Report' do
        let(:report_id) { item.id }
        v2_item_schema('report')

        after { |e| autogenerate_examples(e, 'Returns a Report') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:report_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing Report') }

        run_test!
      end
    end

    delete 'Delete a Report results' do
      v2_auth_header
      tags 'Reports'
      description "Deletes Report's test results"
      operationId 'DeleteReport'
      content_types

      parameter name: :report_id, in: :path, type: :string, required: true

      response '202', "Deletes Report's test results" do
        let(:report_id) { item.id }

        after { |e| autogenerate_examples(e, "Deletes Report's test results") }

        run_test!
      end
    end
  end

  path '/reports/{report_id}/stats' do
    let(:item) do
      FactoryBot.create(
        :v2_report,
        os_major_version: 9,
        supports_minors: [0, 1, 2],
        account: user.account
      )
    end

    get 'Request detailed stats for a Report' do
      v2_auth_header
      tags 'Reports'
      description 'This feature is exclusively used by the frontend'
      deprecated true
      description 'Returns detailed stats for a Report'
      operationId 'ReportStats'
      content_types

      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Returns detailed stats for a Report' do
        let(:report_id) { item.id }
        v2_item_schema('report_stats')

        after { |e| autogenerate_examples(e, 'Returns detailed stats for a Report') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:report_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing Report') }

        run_test!
      end
    end
  end

  path '/systems/{system_id}/reports' do
    let(:system_id) { FactoryBot.create(:system, account: user.account, os_major_version: 8, os_minor_version: 0).id }

    before do
      FactoryBot.create_list(
        :v2_report, 5,
        system_id: system_id,
        os_major_version: 8,
        supports_minors: [0],
        account: user.account
      )
    end

    get 'Request Reports' do
      v2_auth_header
      tags 'Reports'
      description 'Lists Reports'
      operationId 'SystemReports'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Report)
      search_params_v2(V2::Report)

      parameter name: :system_id, in: :path, type: :string, required: true

      response '200', 'Lists Reports' do
        v2_collection_schema 'report'

        after { |e| autogenerate_examples(e, 'List of Reports') }

        run_test!
      end

      response '200', 'Lists Reports' do
        let(:sort_by) { ['title'] }
        v2_collection_schema 'report'

        after { |e| autogenerate_examples(e, 'List of Reports sorted by "title:asc"') }

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
