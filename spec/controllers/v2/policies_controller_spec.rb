# frozen_string_literal: true

require 'rails_helper'

describe V2::PoliciesController do
  let(:attributes) do
    {
      title: :title,
      description: :description,
      business_objective: :business_objective,
      compliance_threshold: :compliance_threshold,
      system_count: :system_count,
      ref_id: :ref_id,
      profile_title: :profile_title,
      os_major_version: :os_major_version
    }
  end

  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:rbac_allowed?) { true }

  before do
    request.headers['X-RH-IDENTITY'] = current_user.account.identity_header.raw
    allow(controller).to receive(:rbac_allowed?).and_return(rbac_allowed?)
  end

  context '/policies' do
    let(:systems) do
      # We are not using these systems, but we need their OS major versions to be passed into factories in sortable
      [7, 8, 9].each_with_object({}) do |i, obj|
        obj["system_#{i}".to_sym] = FactoryBot.create(:system, account: current_user.account, os_major_version: i)
      end
    end

    describe 'GET index' do
      let(:extra_params) { { account: current_user.account, **systems } }
      let(:parents) { nil }
      let(:item_count) { 2 }

      let(:items) do
        FactoryBot.create_list(
          :v2_policy,
          item_count,
          account: current_user.account
        ).sort_by(&:id)
      end

      it_behaves_like 'collection'
      include_examples 'with metadata'
      it_behaves_like 'paginable'
      it_behaves_like 'sortable'
      it_behaves_like 'searchable'
    end

    describe 'GET show' do
      let(:item) { FactoryBot.create(:v2_policy, account: current_user.account) }
      let(:extra_params) { { id: item.id } }

      it_behaves_like 'individual'
    end

    describe 'POST create' do
      let(:profile) { FactoryBot.create(:v2_profile) }
      let(:profile_id) { profile.id }
      let(:title) { 'Policy Title' }
      let(:threshold) { '99.9' }
      let(:description) { 'Policy Description' }
      let(:business_objective) { 'Policy Business Objective' }

      let(:params) do
        {
          profile_id: profile_id,
          title: title,
          compliance_threshold: threshold,
          description: description,
          business_objective: business_objective
        }.compact
      end

      subject { V2::Policy.find(response_body_data['id']) }

      it 'creates a new policy' do
        post :create, params: params

        expect(response).to have_http_status :ok
        expect(subject).not_to be_nil
      end

      context 'invalid profile ID' do
        let(:profile_id) { 'foo' }

        it 'returns with an error' do
          post :create, params: params

          expect(response).to have_http_status :not_acceptable
          expect(response.parsed_body['errors']).to include(match(/profile must exist/))
        end
      end

      context 'unset profile ID' do
        let(:profile_id) { nil }

        it 'returns with an error' do
          post :create, params: params

          expect(response).to have_http_status :not_acceptable
          expect(response.parsed_body['errors']).to include(match(/profile must exist/))
        end
      end

      context 'unset title' do
        let(:title) { nil }

        it 'returns with an error' do
          post :create, params: params

          expect(response).to have_http_status :not_acceptable
          expect(response.parsed_body['errors']).to include(match(/title can't be blank/))
        end
      end

      context 'unset threshold' do
        let(:threshold) { nil }

        it 'returns with an error' do
          post :create, params: params

          expect(response).to have_http_status :not_acceptable
          expect(response.parsed_body['errors']).to include(match(/compliance threshold is not a number/))
        end
      end

      context 'invalid threshold' do
        let(:threshold) { 200 }

        it 'returns with an error' do
          post :create, params: params

          expect(response).to have_http_status :not_acceptable
          expect(response.parsed_body['errors']).to include(match(/compliance threshold must be less than or equal/))
        end
      end
    end

    describe 'PATCH update' do
      let(:item) { FactoryBot.create(:v2_policy, account: current_user.account) }

      let(:params) do
        {
          compliance_threshold: threshold,
          description: description,
          business_objective: business_objective
        }
      end

      let(:threshold) { 80 }
      let(:description) { 'Policy Description' }
      let(:business_objective) { 'Business Objective' }

      (1..described_class::UPDATE_ATTRIBUTES.length + 1).each do |elements|
        described_class::UPDATE_ATTRIBUTES.keys.combination(elements).each do |arr|
          context "using the #{arr.join(', ')} parameters" do
            it 'updates the record' do
              patch :update, params: params.slice(*arr).merge(id: item.id)

              expect(response).to have_http_status :ok
              params.slice(*arr).each do |(key, value)|
                expect(item.reload.send(key)).to eq(value)
              end
            end
          end
        end
      end

      context 'invalid threshold' do
        let(:threshold) { 200 }

        it 'returns with an error' do
          patch :update, params: params.merge(id: item.id)

          expect(response).to have_http_status :not_acceptable
        end
      end
    end

    describe 'DELETE destroy' do
      let(:item) { FactoryBot.create(:v2_policy, account: current_user.account) }

      it 'removes the policy' do
        delete :destroy, params: { id: item.id }

        expect(response).to have_http_status :ok
        expect { item.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'policy under different account' do
        let(:item) { FactoryBot.create(:v2_policy, account: FactoryBot.create(:v2_account)) }

        it 'does not remove the policy' do
          delete :destroy, params: { id: item.id }

          expect(response).to have_http_status :not_found
          expect { item.reload }.not_to raise_error
        end
      end
    end
  end

  context '/systems/:id/policies' do
    before do
      allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym }
      stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ, Rbac::SYSTEM_READ)
    end

    describe 'GET index' do
      let(:extra_params) do
        { account: current_user.account, system_id: parent.id, system_7: parent, system_8: parent, system_9: parent }
      end
      let(:parent) { FactoryBot.create(:system, account: current_user.account) }
      let(:item_count) { 2 }

      let(:items) do
        FactoryBot.create_list(
          :v2_policy,
          item_count,
          account: current_user.account,
          system_id: parent.id,
          os_major_version: parent.os_major_version,
          supports_minors: [parent.os_minor_version]
        ).map(&:reload).sort_by(&:id)
      end

      it_behaves_like 'collection', :systems
      include_examples 'with metadata', :systems
      it_behaves_like 'paginable', :systems
      it_behaves_like 'sortable', :systems
      it_behaves_like 'searchable', :systems
    end
  end
end
