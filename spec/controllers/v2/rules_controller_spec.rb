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

  context '/security_guides/:id/rules' do
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
      let(:item) { FactoryBot.create(:v2_rule) }
      let(:parent) { item.security_guide }
      let(:extra_params) { { security_guide_id: parent.id, id: item.id } }
      let(:notfound_params) { extra_params.merge(security_guide_id: FactoryBot.create(:v2_security_guide).id) }

      it_behaves_like 'individual', :security_guide
      it_behaves_like 'indexable', :ref_id, :security_guide
    end
  end

  context '/security_guides/:id/profiles/:id/rules' do
    let(:attributes) do
      {
        ref_id: :ref_id,
        title: :title,
        rationale: :rationale,
        description: :description,
        severity: :severity,
        remediation_issue_id: :remediation_issue_id,
        precedence: :precedence
      }
    end

    describe 'GET index' do
      let(:parent) { FactoryBot.create(:v2_profile) }
      let(:extra_params) { { security_guide_id: parent.security_guide.id, profile_id: parent.id } }
      let(:item_count) { 2 }

      let(:items) do
        FactoryBot.create_list(
          :v2_rule,
          item_count,
          security_guide: parent.security_guide,
          profile_id: parent.id
        ).sort_by(&:id)
      end

      it_behaves_like 'collection', :security_guide, :profiles
      include_examples 'with metadata', :security_guide, :profiles
      it_behaves_like 'paginable', :security_guide, :profiles
      it_behaves_like 'sortable', :security_guide, :profiles
      it_behaves_like 'searchable', :security_guide, :profiles

      context 'with remediation' do
        let(:items) do
          items = FactoryBot.create_list(
            :v2_rule,
            item_count,
            security_guide: parent.security_guide,
            profile_id: parent.id,
            remediation_available: true
          )

          # The dynamic attribute verification from the shared example does not know about the
          # controller's context of the rule with the joined+selected profile/security_guide fields.
          # Therefore, we need to adjust the Rule outside the controller to be able to call the
          # `remediation_issue_id` method without a failure.
          items.first.class.joins(:security_guide, :profiles)
               .where(security_guide: { id: parent.security_guide.id }, profiles: { id: parent.id })
               .select(
                 items.first.class.arel_table[Arel.star],
                 'security_guide.ref_id AS security_guide__ref_id',
                 'profiles.ref_id AS profiles__ref_id'
               ).order(:id)
        end

        it_behaves_like 'collection', :security_guide, :profiles
      end
    end

    describe 'GET show' do
      let(:parent) { FactoryBot.create(:v2_profile) }
      let(:extra_params) { { security_guide_id: parent.security_guide.id, profile_id: parent.id, id: item.id } }
      let(:notfound_params) { extra_params.merge(security_guide_id: FactoryBot.create(:v2_security_guide).id) }
      let(:item) do
        FactoryBot.create(
          :v2_rule,
          security_guide: parent.security_guide,
          profile_id: parent.id
        )
      end

      it_behaves_like 'individual', :security_guide, :profiles
      it_behaves_like 'indexable', :ref_id, :security_guide, :profiles

      context 'with remediation' do
        let(:item) do
          rule = FactoryBot.create(
            :v2_rule,
            security_guide: parent.security_guide,
            profile_id: parent.id,
            remediation_available: true
          )

          # The dynamic attribute verification from the shared example does not know about the
          # controller's context of the rule with the joined+selected profile/security_guide fields.
          # Therefore, we need to adjust the Rule outside the controller to be able to call the
          # `remediation_issue_id` method without a failure.
          rule.class.joins(:security_guide, :profiles)
              .where(security_guide: { id: rule.security_guide.id }, profiles: { id: parent.id })
              .select(
                rule.class.arel_table[Arel.star],
                'security_guide.ref_id AS security_guide__ref_id',
                'profiles.ref_id AS profiles__ref_id'
              ).find(rule.id)
        end

        it_behaves_like 'individual', :security_guide, :profiles
      end
    end
  end

  context '/policies/:id/tailorings/:id/rules' do
    let(:parent) do
      FactoryBot.create(
        :v2_tailoring,
        policy: FactoryBot.create(:v2_policy, account: current_user.account, supports_minors: [9]),
        os_minor_version: 9
      )
    end

    describe 'GET index' do
      let(:extra_params) do
        {
          policy_id: parent.policy.id,
          tailoring_id: parent.id,
          security_guide_id: pw(parent.profile.security_guide_id)
        }
      end

      let(:item_count) { 2 }

      let(:items) do
        FactoryBot.create_list(
          :v2_rule,
          item_count,
          security_guide_id: parent.profile.security_guide_id,
          tailoring_id: parent.id
        ).sort_by(&:id)
      end

      it_behaves_like 'collection', :policies, :tailorings
      include_examples 'with metadata', :policies, :tailorings
      it_behaves_like 'paginable', :policies, :tailorings
      it_behaves_like 'searchable', :policies, :tailorings
      it_behaves_like 'sortable', :policies, :tailorings
    end

    describe 'PATCH update' do
      let(:item) do
        FactoryBot.create(:v2_rule, security_guide: parent.profile.security_guide)
      end

      let(:params) do
        {
          id: item.id,
          policy_id: parent.policy_id,
          tailoring_id: parent.id,
          parents: %i[policies tailorings]
        }
      end

      it 'creates the link between tailoring and rule' do
        patch :update, params: params

        expect(response).to have_http_status :accepted
        expect(item.tailorings).to include(parent)
      end

      context 'mismatching security guide' do
        let(:item) { FactoryBot.create(:v2_rule) }

        it 'renders model error' do
          patch :update, params: params

          expect(response).to have_http_status :not_acceptable
        end
      end

      context 'rule already linked to the tailoring' do
        let(:item) do
          FactoryBot.create(:v2_rule, security_guide: parent.profile.security_guide, tailoring_id: parent.id)
        end

        it 'returns not found' do
          patch :update, params: params

          expect(response).to have_http_status :not_found
        end
      end

      context 'tailoring belongs to another account' do
        let(:parent) do
          FactoryBot.create(
            :v2_tailoring,
            policy: FactoryBot.create(:v2_policy, supports_minors: [9]),
            os_minor_version: 9
          )
        end

        it 'returns not found' do
          patch :update, params: params

          expect(response).to have_http_status :not_found
        end
      end
    end

    describe 'DELETE destroy' do
      let(:item) do
        FactoryBot.create(:v2_rule, security_guide: parent.profile.security_guide, tailoring_id: parent.id)
      end

      let(:params) do
        {
          id: item.id,
          policy_id: parent.policy_id,
          tailoring_id: parent.id,
          parents: %i[policies tailorings]
        }
      end

      it 'removes the link between a tailoring and a rule' do
        delete :destroy, params: params

        expect(response).to have_http_status :accepted
        expect(item.reload.tailorings).not_to include(parent)
        expect(parent.rules).not_to include(item)
      end

      context 'rule not linked to the system' do
        it 'returns not found' do
          patch :update, params: params

          expect(response).to have_http_status :not_found
        end
      end
    end
  end
end
