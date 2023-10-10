# frozen_string_literal: true

require 'rails_helper'

describe V2::ValueDefinitionsController do
  let(:attributes) do
    {
      ref_id: :ref_id,
      title: :title,
      description: :description,
      value_type: :value_type,
      default_value: :default_value
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
    let(:parent) { FactoryBot.create(:v2_security_guide) }
    let(:extra_params) { { security_guide_id: parent.id } }
    let(:item_count) { 2 }
    let(:items) do
      FactoryBot.create_list(
        :v2_value_definition,
        item_count,
        security_guide: parent
      ).sort_by(&:id)
    end

    it_behaves_like 'collection', :security_guide
    include_examples 'with metadata', :security_guide
    it_behaves_like 'paginable', :security_guide
    it_behaves_like 'sortable', :security_guide
    it_behaves_like 'searchable', :security_guide
  end

  describe 'GET show' do
    let(:item) { FactoryBot.create(:v2_value_definition) }
    let(:parent) { item.security_guide }
    let(:extra_params) { { security_guide_id: parent.id, id: item.id } }
    let(:notfound_params) { extra_params.merge(security_guide_id: FactoryBot.create(:v2_security_guide).id) }

    it_behaves_like 'resource', :security_guide
  end
end
