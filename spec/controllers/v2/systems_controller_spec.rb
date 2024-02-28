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

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
  end

  context '/systems' do
    describe 'GET index' do
      let(:extra_params) { { account: current_user.account } }
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

    describe 'GET index' do
      let(:parent) { FactoryBot.create(:v2_policy, account: current_user.account) }

      let(:extra_params) { { account: current_user.account, policy_id: parent.id } }
      let(:item_count) { 2 }
      let(:items) do
        FactoryBot.create_list(
          :system,
          item_count,
          policy_id: parent.id,
          account: current_user.account
        ).map(&:reload).sort_by(&:id)
      end

      it_behaves_like 'collection', :policies
      include_examples 'with metadata', :policies
      it_behaves_like 'paginable', :policies
      it_behaves_like 'sortable', :policies
      it_behaves_like 'searchable', :policies
    end
  end
end
