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
        :v2_rule,
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
