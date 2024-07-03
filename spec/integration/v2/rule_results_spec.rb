# frozen_string_literal: true

require 'swagger_helper'

describe 'Rule Results', swagger_doc: 'v2/openapi.json' do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:'X-RH-IDENTITY') { user.account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/reports/{report_id}/test_results/{test_result_id}/rule_results' do
    let(:test_result_id) do
      FactoryBot.create(
        :system,
        policy_id: report_id,
        os_major_version: 8,
        os_minor_version: 0,
        account: user.account,
        with_test_result: true
      ).test_results.first.id
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

    get 'Request Rule Results under a Report' do
      v2_auth_header
      tags 'Reports'
      description 'Lists Rule Results under a Report'
      operationId 'ReportRuleResults'
      content_types
      pagination_params_v2
      sort_params_v2(V2::RuleResult)
      search_params_v2(V2::RuleResult)

      parameter name: :test_result_id, in: :path, type: :string, required: true
      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Lists RuleResults' do
        v2_collection_schema 'rule_result'

        after { |e| autogenerate_examples(e, 'List of Rule Results') }

        run_test!
      end

      response '200', 'Lists Rule Results under a Report' do
        let(:sort_by) { ['result'] }
        v2_collection_schema 'rule_result'

        after { |e| autogenerate_examples(e, 'List of Rule Results sorted by "result:asc"') }

        run_test!
      end

      response '200', 'Lists Rule Results under a Report' do
        let(:filter) { '(title=foo)' }
        v2_collection_schema 'rule_result'

        after { |e| autogenerate_examples(e, 'List of Rule Results filtered by "(title=foo)"') }

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
