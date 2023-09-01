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

        nested_route(V2::SecurityGuide) do |parents|
          get :index, params: {
            security_guide_id: security_guide.id,
            parents: parents
          }
        end

        expect(response).to have_http_status :ok
        expect(response_body_data).to match_array(collection)

        response_body_data.each do |vd|
          expect(vd['attributes'].keys.count).to eq(attributes.keys.count)
        end
      end

      include_examples 'with metadata', V2::SecurityGuide do
        let(:extra_params) { { security_guide_id: security_guide.id } }
      end

      it_behaves_like 'paginable', V2::SecurityGuide do
        let(:extra_params) { { security_guide_id: security_guide.id } }
      end

      it_behaves_like 'sortable', V2::SecurityGuide do
        let(:extra_params) { { security_guide_id: security_guide.id } }
      end

      it_behaves_like 'searchable', V2::SecurityGuide do
        let(:extra_params) { { security_guide_id: security_guide.id } }
      end

      context 'multiple security guides' do
        let(:empty_security_guide) { FactoryBot.create(:v2_security_guide) }
        let(:item) { FactoryBot.create(:v2_value_definition) }

        it 'returns no data from empty security guide' do
          nested_route(V2::SecurityGuide) do |parents|
            get :index, params: {
              security_guide_id: empty_security_guide.id,
              parents: parents
            }
          end
          expect(response_body_data).to be_empty
        end
      end
    end

    context 'Unathorized' do
      let(:rbac_allowed?) { false }

      it 'responds with unauthorized status' do
        nested_route(V2::SecurityGuide) do |parents|
          get :index, params: {
            security_guide_id: security_guide.id,
            parents: parents
          }
        end

        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe 'GET show' do
    let(:value_definition) { FactoryBot.create(:v2_value_definition) }
    let(:security_guide) { value_definition.security_guide }

    context 'Authorized' do
      let(:rbac_allowed?) { true }

      it 'returns value_definition by id' do
        item = hash_including('data' => {
                                'id' => value_definition.id,
                                'type' => 'value_definition',
                                'attributes' => attributes.each_with_object({}) do |(key, value), obj|
                                  obj[key.to_s] = value_definition.send(value)
                                end
                              })

        nested_route(V2::SecurityGuide) do |parents|
          get :show, params: {
            security_guide_id: security_guide.id,
            id: value_definition.id,
            parents: parents
          }
        end

        expect(response.parsed_body).to match(item)
      end

      context 'under incorrect parent security guide' do
        let(:item) { FactoryBot.create(:v2_value_definition) }
        let(:security_guide) { FactoryBot.create(:v2_security_guide) }

        it 'returns not_found' do
          nested_route(V2::SecurityGuide) do |parents|
            get :show, params: {
              security_guide_id: security_guide.id,
              id: item.id,
              parents: parents
            }

            expect(response).to have_http_status :not_found
          end
        end
      end
    end
  end
end
