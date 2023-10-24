# frozen_string_literal: true

require 'rails_helper'

describe V2::SecurityGuidesController do
  let(:attributes) do
    {
      ref_id: :ref_id,
      title: :title,
      version: :version,
      description: :description,
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
    let(:extra_params) { {} }
    let(:item_count) { 2 }
    let(:parents) { nil }
    let(:items) { FactoryBot.create_list(:v2_security_guide, item_count).sort_by(&:id) }

    it_behaves_like 'collection'
    include_examples 'with metadata'
    it_behaves_like 'paginable'
    it_behaves_like 'sortable'
    it_behaves_like 'searchable'
  end

  describe 'GET show' do
    let(:item) { FactoryBot.create(:v2_security_guide) }
    let(:extra_params) { { id: item.id } }

    it_behaves_like 'individual'
  end
end
