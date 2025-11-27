# frozen_string_literal: true

require 'rails_helper'

describe V2::RuleResultsController do
  let(:attributes) do
    {
      result: :result,
      rule_id: :rule_id,
      system_id: :system_id,
      ref_id: :ref_id,
      rule_group_id: :rule_group_id,
      title: :title,
      rationale: :rationale,
      description: :description,
      severity: :severity,
      precedence: :precedence,
      identifier: :identifier,
      references: :references,
      remediation_issue_id: :remediation_issue_id
    }
  end

  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:rbac_allowed?) { true }

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
    stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ, Rbac::REPORT_READ)
  end

  context '/reports/:id/test_results/:id/rule_results' do
    let(:report) do
      FactoryBot.create(
        :v2_report,
        assigned_system_count: 0,
        os_major_version: 8,
        supports_minors: [0],
        account: current_user.account
      )
    end

    let(:system) do
      FactoryBot.create(
        :system,
        with_test_result: true,
        policy_id: report.id,
        account: current_user.account,
        os_major_version: 8,
        os_minor_version: 0
      )
    end

    let(:parent) { system.test_results.first }

    describe 'GET index' do
      let(:extra_params) do
        {
          account: current_user.account,
          report_id: report.id,
          test_result_id: parent.id,
          **parent.tailoring.rules.each_with_object({}).with_index do |(rule, obj), idx|
            obj["rule_#{idx + 1}".to_sym] = rule
          end
        }
      end

      let(:item_count) { 2 }

      let(:items) do
        parent.tailoring.rules.sample(item_count).map do |rule|
          FactoryBot.create(:v2_rule_result, rule_id: rule.id, test_result_id: parent.id)
        end.sort_by(&:id)
      end

      it_behaves_like 'collection', :report, :test_result
      include_examples 'with metadata', :report, :test_result
      it_behaves_like 'paginable', :report, :test_result
      it_behaves_like 'sortable', :report, :test_result
      it_behaves_like 'searchable', :report, :test_result

      it 'optimizes queries by using single join path through test_result' do
        controller = described_class.new

        allow(controller).to receive(:permitted_params).and_return(parents: %i[report test_result])
        allow(controller).to receive(:pundit_scope).and_return(V2::RuleResult.all)
        allow(controller).to receive(:join_parents) { |scope, _| scope }

        query = controller.send(:expand_resource).to_sql

        %w[test_result tailoring profile security_guide].each do |association|
          expect(query).to include(association)
        end
        # Verify the optimized query includes the required rule table with proper alias
        expect(query).to include('"rule"')

        join_clauses = query.scan(/JOIN "v2_test_results"/i).count
        expect(join_clauses).to eq(1)
      end
    end
  end
end
