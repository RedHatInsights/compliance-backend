# frozen_string_literal: true

require 'rails_helper'

describe V2::RulesController do
  let(:attributes) do
    {
      ref_id: :ref_id,
      title: :title,
      rationale: :rationale,
      description: :description,
      severity: :severity,
      precedence: :precedence
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
        :v2_rule,
        item_count,
        security_guide: security_guide
      ).sort_by(&:id)
    end

    context 'Authorized' do
      let(:rbac_allowed?) { true }

      it 'returns base fields for each result' do
        collection = items.map do |rule|
          hash_including(
            'id' => rule.id,
            'type' => 'rule',
            **attributes.each_with_object({}) do |(key, value), obj|
              obj[key.to_s] = rule.send(value)
            end
          )
        end

        get :index, params: { security_guide_id: security_guide.id, parents: %i[security_guide] }

        expect(response).to have_http_status :ok
        expect(response_body_data).to match_array(collection)

        response_body_data.each do |rule|
          expect(rule.keys.count).to eq(attributes.keys.count + 2)
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

      context 'under incorrect parent security guide' do
        let(:empty_security_guide) { FactoryBot.create(:v2_security_guide) }
        let(:item) { FactoryBot.create(:v2_rule) }

        it 'returns not_found' do
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
    let(:rule) { FactoryBot.create(:v2_rule) }
    let(:security_guide) { rule.security_guide }

    context 'Authorized' do
      let(:rbac_allowed?) { true }

      it 'returns rule by id' do
        item = hash_including('data' => {
                                'id' => rule.id,
                                'type' => 'rule',
                                **attributes.each_with_object({}) do |(key, value), obj|
                                  obj[key.to_s] = rule.send(value)
                                end
                              })

        get :show, params: { security_guide_id: security_guide.id, id: rule.id, parents: %i[security_guide] }

        expect(response.parsed_body).to match(item)
      end

      context 'under incorrect parent security guide' do
        let(:item) { FactoryBot.create(:v2_rule) }
        let(:security_guide) { FactoryBot.create(:v2_security_guide) }

        it 'returns not_found' do
          get :show, params: { security_guide_id: security_guide.id, id: rule.id, parents: %i[security_guide] }

          expect(response).to have_http_status :not_found
        end
      end
    end
  end
end
