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
      assigned_system_count: -> { 0 },
      reported_system_count: -> { 0 },
      compliant_system_count: -> { 0 },
      unsupported_system_count: -> { 0 }
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
    let(:rhels) do
      [7, 8, 9].each_with_object({}) do |i, obj|
        obj["rhel_#{i}".to_sym] = pw(i)
      end
    end

    describe 'GET index' do
      let(:extra_params) { { account: current_user.account, **rhels } }

      let(:items) do
        FactoryBot.create_list(
          :v2_report, item_count,
          assigned_system_count: 0,
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

      context 'with reporting systems' do
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
            reported_system_count: -> { 4 },
            compliant_system_count: -> { 1 },
            unsupported_system_count: -> { 2 }
          }
        end

        let(:items) do
          FactoryBot.create_list(
            :v2_report, item_count,
            os_major_version: 8,
            supports_minors: [0, 1],
            account: current_user.account
          ).sort_by(&:id)
        end

        it_behaves_like 'collection'

        context 'in inaccessible inventory groups' do
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
              reported_system_count: -> { 4 },
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
    end

    describe 'GET show' do
      let(:extra_params) { { account: current_user.account, id: item.id } }

      let(:item) do
        FactoryBot.create(
          :v2_report,
          os_major_version: 9,
          assigned_system_count: 0,
          supports_minors: [0, 1, 2],
          account: current_user.account
        )
      end

      it_behaves_like 'individual'

      context 'with reporting systems' do
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
            reported_system_count: -> { 4 },
            compliant_system_count: -> { 1 },
            unsupported_system_count: -> { 2 }
          }
        end

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

        context 'in inaccessible inventory groups' do
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
              reported_system_count: -> { 4 },
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

    describe 'DELETE destroy' do
      before { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ, Rbac::POLICY_DELETE) }

      let(:item) do
        FactoryBot.create(
          :v2_report,
          os_major_version: 9,
          assigned_system_count: 1,
          compliant_system_count: 1,
          unsupported_system_count: 0,
          supports_minors: [0],
          account: current_user.account
        )
      end

      it 'removes test_results related to the policy under report' do
        delete :destroy, params: { id: item.id }

        expect(response).to have_http_status :accepted
        expect(item.reload.test_results).to be_empty
      end
    end
  end

  context '/systems/:id/reports' do
    before do
      allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
      stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ, Rbac::SYSTEM_READ)
    end

    describe 'GET index' do
      let(:attributes) do
        {
          title: :title,
          os_major_version: :os_major_version,
          ref_id: :ref_id,
          description: :description,
          profile_title: :profile_title,
          business_objective: :business_objective,
          compliance_threshold: :compliance_threshold,
          all_systems_exposed: -> { false }, # this is inconcistent but we don't care
          reported_system_count: -> { 0 },
          compliant_system_count: -> { 0 },
          unsupported_system_count: -> { 0 }
        }
      end

      let(:extra_params) do
        ver = pw(parent.os_major_version)
        # Pass the same RHEL version under each `rhel_#` parameter as we are under a policy
        { account: current_user.account, system_id: parent.id, rhel_7: ver, rhel_8: ver, rhel_9: ver }
      end
      let(:owner_id) { nil }
      let(:parent) { FactoryBot.create(:system, account: current_user.account, owner_id: owner_id) }
      let(:item_count) { 2 }

      let(:items) do
        FactoryBot.create_list(
          :v2_report,
          item_count,
          account: current_user.account,
          system_id: parent.id,
          os_major_version: parent.os_major_version,
          supports_minors: [parent.os_minor_version]
        ).map(&:reload).sort_by(&:id)
      end

      it_behaves_like 'collection', :systems
      include_examples 'with metadata', :systems
      it_behaves_like 'paginable', :systems
      it_behaves_like 'sortable', :systems
      it_behaves_like 'searchable', :systems
    end
  end
end
