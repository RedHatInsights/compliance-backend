# frozen_string_literal: true

require 'rails_helper'

describe V2::SupportedProfilesController do
  let(:attributes) do
    {
      ref_id: :ref_id,
      title: :title,
      security_guide_version: :security_guide_version,
      os_major_version: :os_major_version,
      os_minor_versions: :os_minor_versions
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
    let(:extra_params) { {} }
    let(:item_count) { 2 }
    let(:parents) { nil }
    let(:v1_profiles) do
      FactoryBot.create(
        :v2_security_guide,
        profile_count: 3,
        os_major_version: 7,
        version: '1.0.0',
        profile_refs: {
          c2s: %w[1 2],
          standard: %w[2],
          hipaa: %w[1],
          ospp: %w[2],
          cui: %w[1 2]
        }
      ).profiles
    end
    let(:v2_profiles) do
      FactoryBot.create(
        :v2_security_guide,
        profile_count: 3,
        os_major_version: 7,
        version: '2.0.0',
        profile_refs: {
          c2s: %w[2],
          standard: %w[1],
          ospp: %w[2]
        }
      ).profiles
    end
    let(:rhel8_profiles) do
      FactoryBot.create(
        :v2_security_guide,
        profile_count: 3,
        os_major_version: 8,
        version: '1.0.0',
        profile_refs: %w[
          c2s hipaa standard cui ospp cis_server_l1 pci-dss stig stig-gui e8 cjis ncp ism_o server rhelh-vpp
        ].each_with_object({}) { |item, obj| obj[item] = %w[0] }
      ).profiles
    end

    let(:items) do
      ids = (rhel8_profiles + v2_profiles + v1_profiles.reject do |profile|
        v2_profiles.map(&:ref_id).include?(profile.ref_id)
      end).map(&:id)

      V2::SupportedProfile.where(id: ids).order(:id)
    end

    it_behaves_like 'collection' do
      let(:extra_params) { { limit: 20 } }
    end
    include_examples 'with metadata' do
      let(:item_count) { 20 }
    end
    it_behaves_like 'paginable'
    it_behaves_like 'sortable'
    it_behaves_like 'searchable'
  end
end
