# frozen_string_literal: true

require 'rails_helper'

describe V2::TestResultsController do
  let(:attributes) do
    {
      end_time: -> { end_time.as_json },
      failed_rule_count: :failed_rule_count,
      display_name: :display_name,
      security_guide_version: :security_guide_version,
      groups: :groups,
      tags: -> { tags.map { |t| t.slice('key', 'namespace', 'value') } },
      os_major_version: :os_major_version,
      os_minor_version: :os_minor_version,
      compliant: :compliant,
      supported: :supported,
      system_id: :system_id
    }
  end

  let(:sysparams) do # Shared parameters for system creation
    { account: current_user.account, os_major_version: 8, os_minor_version: 0, policy_id: parent.id }
  end

  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:rbac_allowed?) { true }

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
    stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ, Rbac::REPORT_READ)
  end

  context '/reports/:id/test_results' do
    let(:parent) do
      report = FactoryBot.create(
        :v2_report,
        assigned_system_count: 0,
        os_major_version: 8,
        supports_minors: [0],
        account: current_user.account
      )

      (1..4).to_a.each do |v|
        sg = FactoryBot.create(:v2_security_guide, os_major_version: report.os_major_version, version: "0.0.#{v}")
        FactoryBot.create(:v2_profile, ref_id: report.ref_id, security_guide: sg, supports_minors: [v])
      end

      report
    end

    describe 'GET index' do
      let(:extra_params) do
        {
          account: current_user.account,
          report_id: parent.id,
          policy: parent.policy,
          system_1: FactoryBot.create(:system, **sysparams),
          system_2: FactoryBot.create(:system, **sysparams)
        }
      end

      let(:item_count) { 2 }

      let(:items) do
        item_count.times.map do
          FactoryBot.create(
            :v2_test_result, system: FactoryBot.create(:system, **sysparams), policy_id: parent.id
          ).reload
        end.sort_by(&:id)
      end

      it_behaves_like 'collection', :report
      include_examples 'with metadata', :report
      it_behaves_like 'paginable', :report
      it_behaves_like 'sortable', :report
      it_behaves_like 'searchable', :report

      context 'system from an inaccessible inventory group' do
        before do
          stub_rbac_permissions(
            Rbac::INVENTORY_HOSTS_READ => [{
              attribute_filter: {
                key: 'group.id',
                operation: 'in',
                value: [nil]
              }
            }]
          )

          items # force-create items

          FactoryBot.create(
            :v2_test_result,
            system: FactoryBot.create(
              :system,
              account: current_user.account,
              os_major_version: 8,
              os_minor_version: 0,
              policy_id: parent.id,
              groups: [{ id: 'a_group' }]
            ),
            policy_id: parent.id
          )
        end

        it 'does not expose the inaccessible system' do
          get :index, params: { report_id: parent.id, parents: [:report] }

          expect(response).to have_http_status :ok
          expect(response_body_data).to match_array(items.map { |item| a_hash_including('id' => item.id) })
        end
      end
    end

    describe 'GET show' do
      let(:item) do
        FactoryBot.create(
          :v2_test_result,
          system: FactoryBot.create(:system, **sysparams),
          policy_id: parent.id
        ).reload
      end

      let(:extra_params) { { report_id: parent.id, id: item.id } }
      let(:notfound_params) { extra_params.merge(report_id: FactoryBot.create(:v2_report).id) }

      it_behaves_like 'individual', :report

      context 'system from an inaccessible inventory group' do
        before do
          stub_rbac_permissions(
            Rbac::INVENTORY_HOSTS_READ => [{
              attribute_filter: {
                key: 'group.id',
                operation: 'in',
                value: [nil]
              }
            }]
          )
        end

        let(:item) do
          FactoryBot.create(
            :v2_test_result,
            system: FactoryBot.create(:system, **sysparams, groups: [{ id: 'a_group' }]),
            policy_id: parent.id
          )
        end

        it 'does not expose the inaccessible system' do
          get :show, params: { id: item.id, report_id: parent.id, parents: [:report] }

          expect(response).to have_http_status :not_found
        end
      end
    end
  end
end
