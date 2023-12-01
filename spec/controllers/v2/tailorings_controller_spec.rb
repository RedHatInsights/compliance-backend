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

  context '/policies/:id/tailorings' do
    describe 'GET index' do
      let(:canonical_profiles) do
        item_count.times.map do |version|
          FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [version])
        end
      end

      let(:parent) do
        FactoryBot.create(
          :v2_policy,
          account: current_user.account,
          profile: canonical_profiles.last
        )
      end
      # passing policy explicitly, to access it's ref_id in YAML fixture
      let(:extra_params) { { policy: parent, policy_id: parent.id } }
      let(:item_count) { 3 }
      let(:items) do
        item_count.times.map do |version|
          FactoryBot.create(
            :v2_tailoring,
            policy: parent,
            profile: canonical_profiles.last,
            os_minor_version: version
          )
        end.sort_by(&:id)
      end

      it_behaves_like 'collection', :policy
      include_examples 'with metadata', :policy
      it_behaves_like 'paginable', :policy
      it_behaves_like 'searchable', :policy
      it_behaves_like 'sortable', :policy
    end
  end

  context '/policies/:id/tailorings/:id' do
    describe 'GET show' do
      let(:os_minor_version) { SecureRandom.random_number(10) }
      let(:canonical_profile) do
        FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [os_minor_version])
      end
      let(:parent) do
        FactoryBot.create(
          :v2_policy,
          account: current_user.account,
          profile: canonical_profile
        )
      end
      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: os_minor_version
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

  context '/policies/:id/tailorings/:id/tailoring_file' do
    describe 'GET tailoring_file with randomly distributed rules' do
      canonical_profile = FactoryBot.create(
        :v2_profile,
        :with_rules,
        security_guide: FactoryBot.create(:v2_security_guide, :with_rules, os_major_version: 9),
        os_major_version: 9,
        ref_id_suffix: 'bar',
        supports_minors: [8]
      )
      let(:parent) do
        FactoryBot.create(
          :v2_policy,
          account: current_user.account,
          profile: canonical_profile
        )
      end
      let(:extra_params) { { policy_id: parent.id, id: item.id } }
      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: 8
        )
      end

      it 'returns XCCDF tailoring file' do
        get :tailoring_file, params: extra_params.reject { |_, ep| ep.is_a?(ActiveRecord::Base) }
                                                 .merge(parents: [:policy])
        expect(response).to have_http_status :ok
        expect(response.headers['Content-Type']).to eq('application/xml')
      end
    end
  end
end
