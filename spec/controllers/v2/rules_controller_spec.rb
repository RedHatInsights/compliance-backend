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
      it_behaves_like 'indexable by ref_id', :security_guide
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
      let(:invalid_params) do
        parent = FactoryBot.create(:v2_profile)
        { security_guide_id: parent.security_guide.id, profile_id: parent.id }
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
      it_behaves_like 'indexable by ref_id', :security_guide, :profiles

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
end
