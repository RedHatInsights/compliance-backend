# frozen_string_literal: true

require 'swagger_helper'

describe 'Test Results', swagger_doc: 'v2/openapi.json' do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:'X-RH-IDENTITY') { user.account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/reports/{report_id}/test_results' do
    before do
      FactoryBot.create_list(
        :system,
        25,
        policy_id: report_id,
        os_major_version: 8,
        os_minor_version: 0,
        account: user.account,
        with_test_result: true
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

    get 'Request Test Results under a Report' do
      v2_auth_header
      tags 'Reports'
      description 'Lists Test Results under a Report'
      operationId 'ReportTestResults'
      content_types
      pagination_params_v2
      sort_params_v2(V2::TestResult)
      search_params_v2(V2::TestResult)

      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Lists TestResults' do
        v2_collection_schema 'test_result'

        after { |e| autogenerate_examples(e, 'List of Test Results') }

        run_test!
      end

      response '200', 'Lists Test Results under a Report' do
        let(:sort_by) { ['score'] }
        v2_collection_schema 'test_result'

        after { |e| autogenerate_examples(e, 'List of Test Results sorted by "score:asc"') }

        run_test!
      end

      response '200', 'Lists Test Results under a Report' do
        let(:filter) { '(os_minor_version=8)' }
        v2_collection_schema 'test_result'

        after { |e| autogenerate_examples(e, 'List of Test Results filtered by "(os_minor_version=8)"') }

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

  path '/reports/{report_id}/test_results/os_versions' do
    before do
      FactoryBot.create_list(
        :system,
        25,
        policy_id: report_id,
        os_major_version: 8,
        os_minor_version: 0,
        account: user.account,
        with_test_result: true
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

    get 'Request the list of available OS versions' do
      v2_auth_header
      tags 'Reports'
      description 'This feature is exclusively used by the frontend'
      operationId 'ReportTestResultsOS'
      content_types
      deprecated true
      search_params_v2(V2::TestResult)

      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Lists available OS versions' do
        schema(type: :array, items: { type: 'string' })

        after { |e| autogenerate_examples(e, 'List of available OS versions') }

        run_test!
      end
    end
  end

  path '/reports/{report_id}/test_results/{test_result_id}' do
    let(:report_id) do
      FactoryBot.create(
        :v2_report,
        account: user.account,
        os_major_version: 8,
        supports_minors: [0],
        assigned_system_count: 0
      ).id
    end

    let(:item) { FactoryBot.create(:system, account: user.account, policy_id: report_id, with_test_result: true) }

    get 'Request a Test Result' do
      v2_auth_header
      tags 'Reports'
      description 'Returns a Test Result under a Report'
      operationId 'ReportTestResult'
      content_types

      parameter name: :test_result_id, in: :path, type: :string, required: true
      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Returns a Test Result under a Report' do
        let(:test_result_id) { item.test_results.first.id }
        v2_item_schema('system')

        after { |e| autogenerate_examples(e, 'Returns a Test Result under a Report') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:test_result_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing Test Result') }

        run_test!
      end
    end
  end
end
