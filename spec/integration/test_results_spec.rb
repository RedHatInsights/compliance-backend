# frozen_string_literal: true

require 'swagger_helper'

describe 'Test Results', swagger_doc: 'v2/openapi.json' do
  let(:user) { FactoryBot.create(:user) }
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
        :report,
        account: user.account,
        os_major_version: 8,
        supports_minors: [0],
        assigned_system_count: 0
      ).id
    end

    get 'Request Test Results under a Report' do
      v2_auth_header
      tags 'Reports'
      description 'Retrieve all of the test results for a specific report.'
      operationId 'ReportTestResults'
      content_types
      tags_params
      pagination_params_v2
      ids_only_param
      sort_params_v2(TestResult)
      search_params_v2(TestResult)

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
        :report,
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
      search_params_v2(TestResult)
      tags_params

      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Lists available OS versions' do
        schema(type: :array, items: { type: 'string' })

        after { |e| autogenerate_examples(e, 'List of available OS versions') }

        run_test!
      end
    end
  end

  path '/reports/{report_id}/test_results/security_guide_versions' do
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
        :report,
        account: user.account,
        os_major_version: 8,
        supports_minors: [0],
        assigned_system_count: 2
      ).id
    end

    get 'Request the list of available Security Guide versions' do
      v2_auth_header
      tags 'Reports'
      description 'This feature is exclusively used by the frontend'
      operationId 'ReportTestResultsSG'
      content_types
      deprecated true
      tags_params

      parameter name: :report_id, in: :path, type: :string, required: true

      response '200', 'Lists available Security Guide versions' do
        schema(type: :array, items: { type: 'string' })

        after { |e| autogenerate_examples(e, 'List of available Security Guide versions') }

        run_test!
      end
    end
  end

  path '/reports/{report_id}/test_results/{test_result_id}' do
    let(:report_id) do
      FactoryBot.create(
        :report,
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
      description 'Retrieve a specific test result for a specific report.'
      operationId 'ReportTestResult'
      content_types
      tags_params

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

  path '/reports/{report_id}/test_results/{test_result_id}/rule_tree' do
    let(:security_guide) { FactoryBot.create(:security_guide, os_major_version: 8) }
    let(:profile) { FactoryBot.create(:profile, security_guide: security_guide, supports_minors: [0]) }
    let(:parent_group) { FactoryBot.create(:rule_group, security_guide: security_guide) }
    let(:child_group) do
      parent_group.children.create!(
        ref_id: "xccdf_org.ssgproject.content_rule_group_#{SecureRandom.hex}",
        title: Faker::Lorem.sentence,
        rationale: Faker::Lorem.paragraph,
        description: Faker::Lorem.paragraph,
        security_guide: security_guide,
        precedence: 2
      )
    end
    let(:rule) do
      FactoryBot.create(:rule, security_guide: security_guide, rule_group: child_group, parent_count: 0)
    end
    let!(:profile_rule) { FactoryBot.create(:profile_rule, profile: profile, rule: rule) }
    let(:report) { FactoryBot.create(:policy, account: user.account, profile: profile) }
    let(:report_id) { report.id }
    let!(:tailoring) { FactoryBot.create(:tailoring, policy: report, profile: profile, os_minor_version: 0) }
    let(:system) do
      FactoryBot.create(
        :system,
        account: user.account,
        policy_id: report_id,
        os_major_version: 8,
        os_minor_version: 0
      )
    end
    let(:test_result) { FactoryBot.create(:test_result, system: system, report_id: report_id) }

    get 'Request the Rule Tree of a Test Result' do
      v2_auth_header
      tags 'Reports'
      description 'Returns the rule tree for the tailoring used by a test result.'
      operationId 'ReportTestResultRuleTree'
      content_types

      parameter name: :report_id, in: :path, type: :string, required: true
      parameter name: :test_result_id, in: :path, type: :string, required: true

      response '200', 'Returns the Rule Tree of a Test Result' do
        let(:test_result_id) { test_result.id }
        schema ref_schema('rule_tree')

        after { |e| autogenerate_examples(e, 'Returns the Rule Tree of a Test Result') }

        run_test! do |response|
          rule_tree = JSON.parse(response.body)
          expect(rule_tree).to eq(test_result.tailoring.rule_tree.as_json)
          expect(rule_tree).to include(
            hash_including(
              'id' => parent_group.id,
              'type' => 'rule_group',
              'children' => [
                hash_including(
                  'id' => child_group.id,
                  'type' => 'rule_group',
                  'children' => [hash_including('id' => rule.id, 'type' => 'rule')]
                )
              ]
            )
          )
        end
      end

      response '403', 'Returns with Forbidden when report access is denied' do
        let(:test_result_id) { test_result.id }
        before { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ) }
        schema(
          type: :object,
          properties: { error: { type: :string } },
          required: ['error']
        )

        run_test!
      end

      response '404', 'Returns with Not Found for a test result under another report' do
        let(:test_result_id) do
          other_report = FactoryBot.create(
            :report,
            account: user.account,
            os_major_version: 8,
            supports_minors: [0],
            assigned_system_count: 0
          )
          FactoryBot.create(:tailoring, policy: Policy.find(other_report.id), os_minor_version: 0)
          FactoryBot.create(
            :system,
            account: user.account,
            policy_id: other_report.id,
            os_major_version: 8,
            os_minor_version: 0,
            with_test_result: true
          ).test_results.first.id
        end
        schema ref_schema('errors')

        run_test!
      end

      response '404', 'Returns with Not Found for a non-existing test result' do
        let(:test_result_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after do |e|
          autogenerate_examples(e, 'Description of an error when requesting a non-existing Test Result rule tree')
        end

        run_test!
      end
    end
  end
end
