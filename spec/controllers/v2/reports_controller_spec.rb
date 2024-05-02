# frozen_string_literal: true

require 'rails_helper'

describe V2::ReportsController do
  let(:attributes) do
    {
      title: :title,
      os_major_version: :os_major_version,
      ref_id: :ref_id,
      description: :description,
      profile_title: :profile_title,
      business_objective: :business_objective,
      all_systems_exposed: -> { true },
      compliance_threshold: :compliance_threshold,
      assigned_system_count: -> { 4 },
      result_system_count: -> { 4 },
      compliant_system_count: -> { 1 },
      unsupported_system_count: -> { 2 }
    }
  end
  before { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ, Rbac::REPORT_READ) }

  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:rbac_allowed?) { true }

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
  end

  context '/reports' do
    describe 'GET index' do
      let(:extra_params) { { account: current_user.account } }

      let(:items) do
        FactoryBot.create_list(
          :v2_report, item_count,
          os_major_version: 8,
          supports_minors: [0, 1],
          account: current_user.account
        ).sort_by(&:id)
      end

      it_behaves_like 'collection'
      include_examples 'with metadata'
      it_behaves_like 'paginable'
      it_behaves_like 'sortable'
      it_behaves_like 'searchable'

      context 'with systems in inaccessible inventory groups' do
        let(:attributes) do
          {
            title: :title,
            os_major_version: :os_major_version,
            ref_id: :ref_id,
            description: :description,
            profile_title: :profile_title,
            business_objective: :business_objective,
            all_systems_exposed: -> { false },
            compliance_threshold: :compliance_threshold,
            assigned_system_count: -> { 4 },
            result_system_count: -> { 4 },
            compliant_system_count: -> { 1 },
            unsupported_system_count: -> { 2 }
          }
        end

        before do
          stub_rbac_permissions(
            Rbac::INVENTORY_HOSTS_READ => [{
              attribute_filter: {
                key: 'group.id',
                operation: 'in',
                value: [nil] # access to ungrouped hosts
              }
            }]
          )

          items.each do |report|
            system = FactoryBot.create(
              :system,
              account: current_user.account,
              os_minor_version: 0,
              group_count: 2, # host grouped in Inventory Groups
              policy_id: report.id
            )
            FactoryBot.create(
              :v2_test_result,
              system: system,
              account: current_user.account,
              score: SecureRandom.rand(100),
              supported: true,
              policy_id: report.id
            )
          end
        end

        it_behaves_like 'collection'
      end
    end

    describe 'GET show' do
      let(:extra_params) { { account: current_user.account, id: item.id } }

      let(:item) do
        FactoryBot.create(
          :v2_report,
          os_major_version: 9,
          assigned_system_count: 4,
          compliant_system_count: 1,
          unsupported_system_count: 2,
          supports_minors: [0, 1, 2],
          account: current_user.account
        )
      end

      it_behaves_like 'individual'

      context 'with systems in inaccessible inventory groups' do
        let(:attributes) do
          {
            title: :title,
            os_major_version: :os_major_version,
            ref_id: :ref_id,
            description: :description,
            profile_title: :profile_title,
            business_objective: :business_objective,
            all_systems_exposed: -> { false },
            compliance_threshold: :compliance_threshold,
            assigned_system_count: -> { 4 },
            result_system_count: -> { 4 },
            compliant_system_count: -> { 1 },
            unsupported_system_count: -> { 2 }
          }
        end

        before do
          stub_rbac_permissions(
            Rbac::INVENTORY_HOSTS_READ => [{
              attribute_filter: {
                key: 'group.id',
                operation: 'in',
                value: [nil] # access to ungrouped hosts
              }
            }]
          )

          FactoryBot.create_list(
            :system, 3,
            account: current_user.account,
            os_major_version: 9,
            os_minor_version: 0,
            group_count: 2,
            policy_id: item.id
          ).each do |system|
            FactoryBot.create(
              :v2_test_result,
              system: system,
              account: current_user.account,
              score: SecureRandom.rand(100),
              supported: true,
              policy_id: item.id
            )
          end
        end

        it_behaves_like 'individual'
      end
    end
  end
end
