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
    let(:items) { FactoryBot.create_list(:v2_security_guide, item_count).sort_by(&:id) }

    it_behaves_like 'collection'
    include_examples 'with metadata'
    it_behaves_like 'paginable'
    it_behaves_like 'sortable'
    it_behaves_like 'searchable'
  end

  describe 'GET show' do
    let(:security_guide) { FactoryBot.create(:v2_security_guide) }

    context 'Authorized' do
      let(:rbac_allowed?) { true }

      it 'returns security guide by id' do
        item = hash_including('data' => {
                                'id' => security_guide.id,
                                'type' => 'security_guide',
                                **attributes.each_with_object({}) do |(key, value), obj|
                                  obj[key.to_s] = security_guide.send(value)
                                end
                              })

        get :show, params: { id: security_guide.id }

        expect(response.parsed_body).to match(item)
      end
    end

    context 'Unathorized' do
      let(:rbac_allowed?) { false }

      it 'responds with unathorized status' do
        get :show, params: { id: security_guide.id }

        expect(response).to have_http_status :forbidden
      end
    end
  end
end
