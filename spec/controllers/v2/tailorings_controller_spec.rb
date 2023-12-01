# frozen_string_literal: true

require 'rails_helper'

describe V2::TailoringsController do
  let(:attributes) do
    {
      profile_id: :profile_id,
      value_overrides: :value_overrides,
      os_minor_version: :os_minor_version,
      os_major_version: :os_major_version
    }
  end

  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:rbac_allowed?) { true }

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
  end

  describe 'GET index' do
    let(:profile) { FactoryBot.create(:v2_profile) }
    let(:parent) do
      FactoryBot.create(
        :v2_policy,
        account: current_user.account,
        profile: profile
      )
    end
    let(:item_count) { 2 }
    let(:items) do
      FactoryBot.create_list(
        :v2_tailoring,
        item_count,
        policy_id: parent.id,
        profile_id: profile.id
      ).sort_by(&:id)
    end
    let(:extra_params) { { policy_id: parent.id } }

    it_behaves_like 'collection', :policy
    it_behaves_like 'paginable', :policy
    it_behaves_like 'searchable', :policy
    it_behaves_like 'sortable', :policy
  end

  describe 'GET show' do
    let(:profile) { FactoryBot.create(:v2_profile) }
    let(:parent) do
      FactoryBot.create(
        :v2_policy,
        account: current_user.account,
        profile: profile
      )
    end
    let(:item) do
      FactoryBot.create(
        :v2_tailoring,
        policy_id: parent.id,
        profile_id: profile.id
      )
    end
    let(:extra_params) { { policy_id: parent.id, id: item.id } }
    let(:notfound_params) do
      extra_params.merge(policy_id: FactoryBot.create(
        :v2_policy,
        account: current_user.account,
        profile: FactoryBot.create(:v2_profile)
      ).id)
    end

    it_behaves_like 'individual', :policy
  end
end
