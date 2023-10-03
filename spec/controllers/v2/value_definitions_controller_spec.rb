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

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
  end

  describe 'GET index' do
    let(:item_count) { 2 }
    let(:security_guide) { FactoryBot.create(:v2_security_guide) }
    let(:items) do
      FactoryBot.create_list(
        :v2_value_definition,
        item_count,
        security_guide: security_guide
      ).sort_by(&:id)
    end

    context 'Authorized' do
      let(:rbac_allowed?) { true }

      it 'returns base fields for each result' do
        collection = items.map do |vd|
          hash_including(
            'id' => vd.id,
            'type' => 'value_definition',
            'attributes' => attributes.each_with_object({}) do |(key, value), obj|
              obj[key.to_s] = vd.send(value)
            end
          )
        end

        get :index, params: { security_guide_id: security_guide.id, parents: %i[security_guide] }

        expect(response).to have_http_status :ok
        expect(response_body_data).to match_array(collection)

        response_body_data.each do |vd|
          expect(vd['attributes'].keys.count).to eq(attributes.keys.count)
        end
      end

      include_examples 'with metadata', :security_guide do
        let(:extra_params) { { security_guide_id: security_guide.id } }
      end

      it_behaves_like 'paginable', :security_guide do
        let(:extra_params) { { security_guide_id: security_guide.id } }
      end

      it_behaves_like 'sortable', :security_guide do
        let(:extra_params) { { security_guide_id: security_guide.id } }
      end

      it_behaves_like 'searchable', :security_guide do
        let(:extra_params) { { security_guide_id: security_guide.id } }
      end

      context 'multiple security guides' do
        let(:empty_security_guide) { FactoryBot.create(:v2_security_guide) }
        let(:item) { FactoryBot.create(:v2_value_definition) }

        it 'returns no data from empty security guide' do
          get :index, params: { security_guide_id: empty_security_guide.id, parents: %i[security_guide] }

          expect(response_body_data).to be_empty
        end
      end
    end

    context 'Unathorized' do
      let(:rbac_allowed?) { false }

      it 'responds with unauthorized status' do
        get :index, params: { security_guide_id: security_guide.id, parents: %i[security_guide] }

        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe 'GET show' do
    let(:item) { FactoryBot.create(:v2_value_definition) }
    let(:security_guide) { item.security_guide }

    context 'Authorized' do
      let(:rbac_allowed?) { true }

      it_behaves_like 'show', :security_guide do
        let(:extra_params) { { security_guide_id: security_guide.id, id: item.id } }
      end

      context 'under incorrect parent security guide' do
        let(:security_guide) { FactoryBot.create(:v2_security_guide) }

        it 'returns not_found' do
          get :show, params: {
            security_guide_id: security_guide.id,
            id: item.id,
            parents: %i[security_guide]
          }

          expect(response).to have_http_status :not_found
        end
      end
    end
  end
end
