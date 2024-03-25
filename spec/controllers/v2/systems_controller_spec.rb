# frozen_string_literal: true

require 'rails_helper'

describe V2::SystemsController do
  before { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ, Rbac::SYSTEM_READ) }

  let(:attributes) do
    {
      display_name: :display_name,
      groups: :groups,
      culled_timestamp: -> { culled_timestamp.as_json },
      stale_timestamp: -> { stale_timestamp.as_json },
      stale_warning_timestamp: -> { stale_warning_timestamp.as_json },
      updated: -> { updated.as_json },
      insights_id: :insights_id,
      tags: :tags,
      policies: -> { policies.map { |policy| { id: policy.id, title: policy.title } } },
      os_major_version: -> { system_profile&.dig('operating_system', 'major') },
      os_minor_version: -> { system_profile&.dig('operating_system', 'minor') }
    }
  end

  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:rbac_allowed?) { true }
  let(:meta_keys) { %w[total limit offset tags] }

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
  end

  context '/systems' do
    describe 'GET index' do
      let(:policies) do
        [7, 8, 9].each_with_object({}) do |i, obj|
          obj["policy_#{i}".to_sym] = FactoryBot.create(
            :v2_policy,
            account: current_user.account,
            os_major_version: i,
            supports_minors: [1, 2, 8]
          )
        end
      end

      let(:extra_params) { { account: current_user.account, **policies } }
      let(:parents) { nil }
      let(:item_count) { 2 }

      let(:items) do
        FactoryBot.create_list(
          :system,
          item_count,
          account: current_user.account
        ).map(&:reload).sort_by(&:id)
      end

      it_behaves_like 'collection'
      include_examples 'with metadata'
      it_behaves_like 'paginable'
      it_behaves_like 'sortable'
      it_behaves_like 'searchable'
      it_behaves_like 'taggable'
    end

    describe 'GET show' do
      let(:item) { FactoryBot.create(:system, account: current_user.account).reload }
      let(:extra_params) { { id: item.id } }

      it_behaves_like 'individual'
    end
  end

  context '/policies/:id/systems' do
    let(:attributes) do
      {
        display_name: :display_name,
        groups: :groups,
        culled_timestamp: -> { culled_timestamp.as_json },
        stale_timestamp: -> { stale_timestamp.as_json },
        stale_warning_timestamp: -> { stale_warning_timestamp.as_json },
        updated: -> { updated.as_json },
        insights_id: :insights_id,
        tags: :tags,
        os_major_version: -> { system_profile&.dig('operating_system', 'major') },
        os_minor_version: -> { system_profile&.dig('operating_system', 'minor') }
      }
    end

    let(:parent) do
      FactoryBot.create(:v2_policy, :for_tailoring, account: current_user.account, supports_minors: [0, 1, 2, 8])
    end

    describe 'GET index' do
      let(:extra_params) do
        { account: current_user.account, policy_id: parent.id, policy_7: parent, policy_8: parent, policy_9: parent }
      end
      let(:item_count) { 2 }
      let(:items) do
        FactoryBot.create_list(
          :system,
          item_count,
          policy_id: parent.id,
          account: current_user.account,
          os_minor_version: 8
        ).map(&:reload).sort_by(&:id)
      end

      it_behaves_like 'collection', :policies
      include_examples 'with metadata', :policies
      it_behaves_like 'paginable', :policies
      it_behaves_like 'sortable', :policies
      it_behaves_like 'searchable', :policies
      it_behaves_like 'taggable', :policies
    end

    describe 'PATCH update' do
      let(:item) do
        FactoryBot.create(
          :system,
          account: current_user.account,
          os_major_version: os_major_version,
          os_minor_version: os_minor_version
        )
      end

      let(:os_major_version) { parent.os_major_version }
      let(:os_minor_version) { parent.os_minor_versions.sample }
      let(:first_tailoring) { parent.tailorings.first }

      it 'creates the link between a policy and a system' do
        patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

        expect(response).to have_http_status :accepted
        expect(item.policies).to include(parent)
      end

      it 'creates a tailoring with default rules and values' do
        patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

        expect(response).to have_http_status :accepted
        expect(parent.tailorings).to contain_exactly(
          an_object_having_attributes(os_minor_version: os_minor_version.to_s)
        )

        expect(first_tailoring.rules.to_set(&:id)).to eq(first_tailoring.profile.rules.to_set(&:id))
        expect(first_tailoring.value_overrides).to eq(first_tailoring.profile.value_overrides)
      end

      context 'tailoring already exists' do
        before do
          FactoryBot.create(
            :system,
            account: current_user.account,
            policy_id: parent.id,
            os_minor_version: os_minor_version,
            os_major_version: os_major_version
          )
          first_tailoring.rules -= [first_tailoring.rules.sample]
          first_tailoring.value_overrides['foo'] = 'bar'
        end

        it 'does not create a new tailoring' do
          patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :accepted
          expect(parent.tailorings).to contain_exactly(
            an_object_having_attributes(os_minor_version: os_minor_version.to_s)
          )
          expect(first_tailoring.rules).not_to eq(first_tailoring.profile.rules)
          expect(first_tailoring.value_overrides).not_to eq(first_tailoring.profile.value_overrides)
        end

        context 'with newer profile variant becoming available' do
          before do
            FactoryBot.create(
              :v2_profile,
              ref_id: first_tailoring.profile.ref_id,
              security_guide: FactoryBot.create(
                :v2_security_guide,
                os_major_version: first_tailoring.profile.security_guide.os_major_version,
                version: first_tailoring.profile.security_guide.version.split('.').tap do |arr|
                  arr.map! { |i| i.to_i + 1 } # Increment all digits in the version number by 1
                end.join('.')
              ),
              supports_minors: [os_minor_version]
            )
          end

          it 'does not create a new tailoring' do
            patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

            expect(response).to have_http_status :accepted
            expect(parent.tailorings).to contain_exactly(
              an_object_having_attributes(os_minor_version: os_minor_version.to_s)
            )
          end
        end
      end

      context 'policy already linked to the system' do
        let(:item) { FactoryBot.create(:system, account: current_user.account, policy_id: parent.id) }

        it 'returns not found' do
          patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :not_found
        end
      end

      context 'policy belonging to another account' do
        let(:parent) do
          FactoryBot.create(
            :v2_policy,
            account: FactoryBot.create(:v2_account),
            supports_minors: [0, 1, 2, 8]
          )
        end

        it 'returns not found' do
          patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :not_found
        end
      end

      context 'system in an inaccessible inventory group' do
        before do
          stub_rbac_permissions(
            Rbac::INVENTORY_HOSTS_READ => [{
              attribute_filter: {
                key: 'group.id',
                operation: 'in',
                value: ['not_this_group']
              }
            }]
          )
        end

        let(:item) { FactoryBot.create(:system, account: current_user.account, group_count: 1) }

        it 'returns not found' do
          patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :not_found
        end
      end

      context 'OS major version mismatch' do
        let(:os_major_version) { 6 }

        it 'fails with an error' do
          patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :not_acceptable
          expect(response.parsed_body['errors']).to include(match(/Unsupported OS major/))
        end
      end

      context 'OS minor version mismatch' do
        let(:os_minor_version) { 6 }

        it 'fails with an error' do
          patch :update, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :not_acceptable
          expect(response.parsed_body['errors']).to include(match(/Unsupported OS minor/))
        end
      end
    end

    # TODO: tailoring deletion if no other systems are assigned
    describe 'DELETE destroy' do
      let(:item) { FactoryBot.create(:system, account: current_user.account, policy_id: parent.id) }

      it 'removes the link between a policy and a system' do
        delete :destroy, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

        expect(response).to have_http_status :accepted
        expect(item.policies).not_to include(parent)
        expect(parent.systems).not_to include(item)
      end

      context 'policy not linked to the system' do
        let(:item) { FactoryBot.create(:system, account: current_user.account) }

        it 'returns not found' do
          delete :destroy, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :not_found
        end
      end

      context 'multiple policies linked to the system' do
        let(:policy) do
          FactoryBot.create(
            :v2_policy,
            account: current_user.account,
            supports_minors: [0, 1, 2, 8]
          )
        end

        before { FactoryBot.create(:v2_policy_system, policy: policy, system: item) }

        it 'does not touch the link of the second policy' do
          delete :destroy, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :accepted
          expect(item.policies).to include(policy)
        end
      end

      context 'multiple systems linked to a policy' do
        let!(:system) { FactoryBot.create(:system, account: current_user.account, policy_id: parent.id) }

        it 'does not touch the link of the second system' do
          delete :destroy, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :accepted
          expect(parent.systems).to include(system)
        end
      end

      context 'system in an inaccessible inventory group' do
        before do
          stub_rbac_permissions(
            Rbac::INVENTORY_HOSTS_READ => [{
              attribute_filter: {
                key: 'group.id',
                operation: 'in',
                value: ['not_this_group']
              }
            }]
          )
        end

        let(:item) { FactoryBot.create(:system, account: current_user.account, group_count: 1) }

        it 'returns not found' do
          delete :destroy, params: { id: item.id, policy_id: parent.id, parents: [:policies] }

          expect(response).to have_http_status :not_found
        end
      end
    end
  end
end
