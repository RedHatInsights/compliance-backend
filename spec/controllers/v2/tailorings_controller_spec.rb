# frozen_string_literal: true

require 'rails_helper'

describe V2::TailoringsController do
  let(:attributes) do
    {
      profile_id: :profile_id,
      value_overrides: :value_overrides,
      os_minor_version: :os_minor_version,
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

  context '/policies/:id/tailorings' do
    describe 'GET index' do
      # Build a set of canonical profiles for various OS minor versions across Security Guides (Benchmarks).
      let(:canonical_profiles) do
        item_count.times.map do |version|
          FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [version])
        end
      end

      let(:parent) do
        FactoryBot.create(
          :v2_policy,
          account: current_user.account,
          profile: canonical_profiles.last
        )
      end
      let(:extra_params) { { ref_id: pw(parent.ref_id), policy_id: parent.id } }
      let(:item_count) { 3 }
      let(:items) do
        item_count.times.map do |version|
          FactoryBot.create(
            :v2_tailoring,
            policy: parent,
            profile: canonical_profiles.last,
            os_minor_version: version
          )
        end.sort_by(&:id)
      end

      it_behaves_like 'collection', :policy
      include_examples 'with metadata', :policy
      it_behaves_like 'paginable', :policy
      it_behaves_like 'searchable', :policy
      it_behaves_like 'sortable', :policy
    end

    describe 'GET show' do
      let(:os_minor_version) { SecureRandom.random_number(10) }
      let(:canonical_profile) do
        FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [os_minor_version])
      end
      let(:parent) do
        FactoryBot.create(
          :v2_policy,
          account: current_user.account,
          profile: canonical_profile
        )
      end
      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: os_minor_version
        )
      end

      let(:extra_params) { { policy_id: parent.id, id: item.id } }
      let(:notfound_params) do
        extra_params.merge(policy_id: FactoryBot.create(
          :v2_policy,
          account: current_user.account,
          profile: FactoryBot.create(:v2_profile)
        ).id)
      end

      it_behaves_like 'individual', :policy
      it_behaves_like 'indexable', :os_minor_version, :policy
    end
  end

  context '/policies/:id/tailorings/:id/tailoring_file' do
    before do
      header = JSON.parse(Base64.decode64(current_user.account.identity_header.raw))
      header['identity']['auth_type'] = Insights::Api::Common::IdentityHeader::CERT_AUTH
      request.headers['X-RH-IDENTITY'] = Base64.encode64(header.to_json)
    end

    let(:parent) do
      FactoryBot.create(
        :v2_policy,
        account: current_user.account,
        profile: canonical_profile
      )
    end
    let(:extra_params) { { policy_id: parent.id, id: item.id } }

    context 'with no rules and no values' do
      let(:canonical_profile) do
        FactoryBot.create(
          :v2_profile,
          rule_count: 5,
          value_count: 5,
          security_guide: FactoryBot.create(:v2_security_guide, rule_count: 3, os_major_version: 9),
          os_major_version: 9,
          ref_id_suffix: 'bar',
          supports_minors: [8]
        )
      end
      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          rules: [],
          value_overrides: [],
          policy: parent,
          profile: canonical_profile,
          os_minor_version: 8
        )
      end

      it 'returns XCCDF tailoring file with unselected rules' do
        get :tailoring_file, params: extra_params.merge(parents: [:policy])

        tailoring_file = Nokogiri::XML(response.body).remove_namespaces!
        deselected, selected = tailoring_file.xpath('//Profile/select')
                                             .partition { |sel| sel.attributes['selected'].value == 'false' }

        expect(response).to have_http_status :ok
        expect(deselected.map { |r| r.attributes['idref'].value }).to match_array(item.profile.rules.map(&:ref_id))
        expect(selected).to match_array(item.rules.map(&:ref_id))
      end
    end

    context 'with default rules and values' do
      let(:canonical_profile) do
        FactoryBot.create(
          :v2_profile,
          rule_count: 5,
          value_count: 5,
          security_guide: FactoryBot.create(:v2_security_guide, rule_count: 3, os_major_version: 9),
          os_major_version: 9,
          ref_id_suffix: 'bar',
          supports_minors: [8]
        )
      end
      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          :with_default_rules,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: 8
        )
      end

      it 'returns empty response' do
        get :tailoring_file, params: extra_params.merge(parents: [:policy])

        expect(response).to have_http_status :no_content
      end
    end

    context 'with no tailored rules, but tailored values' do
      let(:canonical_profile) do
        FactoryBot.create(
          :v2_profile,
          rule_count: 5,
          value_count: 5,
          security_guide: FactoryBot.create(:v2_security_guide, rule_count: 3, os_major_version: 9),
          os_major_version: 9,
          ref_id_suffix: 'bar',
          supports_minors: [8]
        )
      end
      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          :with_tailored_values,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: 8
        )
      end

      it 'returns tailored values and default set of rules, but unselected' do
        get :tailoring_file, params: extra_params.merge(parents: [:policy])

        tailoring_file = Nokogiri::XML(response.body).remove_namespaces!
        selected, deselected = tailoring_file.xpath('//Profile/select')
                                             .partition { |sel| sel.attributes['selected'].value == 'true' }
        values = tailoring_file.xpath('//Profile/set-value/@idref')

        expect(response).to have_http_status :ok
        expect(selected).to be_empty
        expect(deselected).not_to be_empty
        expect(deselected.map { |r| r.attributes['selected'].value }.uniq).to eq(['false'])
        expect(values).not_to be_empty
      end
    end

    context 'with randomly distributed rules' do
      let(:canonical_profile) do
        FactoryBot.create(
          :v2_profile,
          rule_count: 5,
          value_count: 5,
          security_guide: FactoryBot.create(:v2_security_guide, rule_count: 3, os_major_version: 9),
          os_major_version: 9,
          ref_id_suffix: 'bar',
          supports_minors: [8]
        )
      end
      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          :with_mixed_rules,
          :with_tailored_values,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: 8
        )
      end

      it 'returns XCCDF tailoring file' do
        get :tailoring_file, params: extra_params.merge(parents: [:policy])

        tailoring_values = V2::Tailoring.find(extra_params[:id]).value_overrides.keys
        tailoring_file = Nokogiri::XML(response.body).remove_namespaces!
        tailored_values = tailoring_file.xpath('//Profile/set-value/@idref')
        selected, = tailoring_file.xpath('//Profile/select')
                                  .partition { |sel| sel.attributes['selected'].value == 'true' }
        rules_and_groups = selected.map { |r| r.attributes['idref'].value }
        rules_only = rules_and_groups.select { |r| r.exclude?('content_rule_group') }

        expect(response).to have_http_status :ok
        expect(response.headers['Content-Type']).to eq('application/xml')
        expect(tailoring_values).to eq(tailored_values.map(&:value))
        expect(rules_only).to match_array(item.rules_added.map(&:ref_id))
        expect(rules_and_groups - rules_only).to match_array(item.rule_group_ref_ids)
      end
    end

    context 'with unauthorized policy' do
      let(:canonical_profile) do
        FactoryBot.create(:v2_profile)
      end
      let(:extra_params) do
        {
          # policy of a foreign account
          policy_id: FactoryBot.create(:v2_policy, account: FactoryBot.create(:v2_account)),
          id: item.id
        }
      end
      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: 8
        )
      end

      it 'results in 404 error' do
        get :tailoring_file, params: extra_params.merge(parents: [:policy])

        expect(response).to have_http_status :not_found
      end
    end

    context 'with mismatching set of IDs' do
      let(:canonical_profile) do
        FactoryBot.create(:v2_profile)
      end
      let(:extra_params) do
        {
          policy_id: FactoryBot.create(:v2_policy, account: FactoryBot.create(:v2_account)),
          id: Faker::Internet.uuid
        }
      end

      it 'results in 404 error' do
        get :tailoring_file, params: extra_params.merge(parents: [:policy])

        expect(response).to have_http_status :not_found
      end
    end
  end
end
