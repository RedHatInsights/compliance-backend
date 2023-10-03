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

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
  end

  describe 'GET index' do
    let(:item_count) { 2 }
    let(:items) { FactoryBot.create_list(:v2_security_guide, item_count).sort_by(&:id) }

    context 'Authorized' do
      let(:rbac_allowed?) { true }

      it 'returns base fields for each result' do
        collection = items.map do |sg|
          hash_including(
            'id' => sg.id,
            'type' => 'security_guide',
            'attributes' => attributes.each_with_object({}) do |(key, value), obj|
              obj[key.to_s] = sg.send(value)
            end
          )
        end

        get :index

        expect(response).to have_http_status :ok
        expect(response_body_data).to match_array(collection)

        response_body_data.each do |sg|
          expect(sg['attributes'].keys.count).to eq(attributes.keys.count)
        end
      end

      it_behaves_like 'searchable'
      it_behaves_like 'paginable'
      it_behaves_like 'sortable'
      include_examples 'with metadata'
    end

    context 'Unathorized' do
      let(:rbac_allowed?) { false }
      it 'responds with unauthorized status' do
        get :index

        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe 'GET show' do
    let(:item) { FactoryBot.create(:v2_security_guide) }

    context 'Authorized' do
      let(:rbac_allowed?) { true }

      it_behaves_like 'show' do
        let(:extra_params) { { id: item.id } }
      end
    end

    context 'Unathorized' do
      let(:rbac_allowed?) { false }

      it 'responds with unathorized status' do
        get :show, params: { id: item.id }

        expect(response).to have_http_status :forbidden
      end
    end
  end
end
