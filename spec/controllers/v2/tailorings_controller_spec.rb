# frozen_string_literal: true

require 'rails_helper'

describe V2::TailoringsController do
  let(:attributes) do
    {
      profile_id: :profile_id,
      security_guide_id: :security_guide_id,
      security_guide_version: :security_guide_version,
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
      let(:canonical_profiles) do
        item_count.times.map do |version|
          FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [version])
        end
      end

      let(:parent) { FactoryBot.create(:v2_policy, account: current_user.account, profile: canonical_profiles.last) }
      let(:extra_params) { { ref_id: pw(parent.ref_id), policy_id: parent.id } }
      let(:item_count) { 3 }

      let(:items) do
        item_count.times.map do |version|
          FactoryBot.create(:v2_tailoring, policy: parent, os_minor_version: version)
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
      let(:parent) { FactoryBot.create(:v2_policy, account: current_user.account, profile: canonical_profile) }
      let(:item) { FactoryBot.create(:v2_tailoring, policy: parent, os_minor_version: os_minor_version) }
      let(:extra_params) { { policy_id: parent.id, id: item.id } }

      let(:canonical_profile) do
        FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [os_minor_version])
      end

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

    describe 'GET rule_tree' do
      let(:os_minor_version) { SecureRandom.random_number(10) }
      let(:parent) { FactoryBot.create(:v2_policy, account: current_user.account, profile: canonical_profile) }

      let(:item) do
        FactoryBot.create(:v2_tailoring, :with_mixed_rules, policy: parent, os_minor_version: os_minor_version)
      end

      let(:canonical_profile) do
        FactoryBot.create(:v2_profile, rule_count: 5, ref_id_suffix: 'foo', supports_minors: [os_minor_version])
      end

      it 'calls the rule tree on the model' do
        get :rule_tree, params: { id: item.id, policy_id: parent.id, parents: %i[policy] }

        expect(response).to have_http_status :ok
        expect(response.parsed_body).not_to be_empty
      end
    end

    describe 'POST create' do
      let(:os_minor_version) { SecureRandom.random_number(10) }
      let(:parent) { FactoryBot.create(:v2_policy, account: current_user.account, profile: canonical_profile) }
      let(:params) { { policy_id: parent.id, os_minor_version: os_minor_version, parents: [:policy] } }

      let(:canonical_profile) do
        FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [os_minor_version])
      end

      it 'creates a tailoring according to the OS minor version' do
        post :create, params: params

        expect(response).to have_http_status :created
        expect(parent.tailorings.map(&:id)).to include(response_body_data['id'])
      end

      context 'tailoring already exists' do
        before { FactoryBot.create(:v2_tailoring, policy: parent, os_minor_version: os_minor_version) }

        it 'fails with an error' do
          post :create, params: params

          expect(response).to have_http_status :not_acceptable
        end
      end

      context 'unsupported OS minor version' do
        let(:canonical_profile) { FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: []) }

        it 'returns not found' do
          post :create, params: params

          expect(response).to have_http_status :not_found
        end
      end
    end

    describe 'PATCH update' do
      let(:os_minor_version) { SecureRandom.random_number(10) }
      let(:parent) { FactoryBot.create(:v2_policy, account: current_user.account, profile: canonical_profile) }
      let(:item) { FactoryBot.create(:v2_tailoring, policy: parent, os_minor_version: os_minor_version) }
      let(:params) { { value_overrides: value_overrides, policy_id: parent.id, id: item.id, parents: [:policy] } }

      let(:canonical_profile) do
        FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [os_minor_version])
      end

      let(:value_overrides) { item.value_overrides.transform_values { SecureRandom.random_number(1000).to_s } }

      it 'updates value_overrides' do
        patch :update, params: params

        expect(response).to have_http_status :accepted
        expect(item.reload.value_overrides).to eq(value_overrides)
      end

      context 'string value for a string value definition' do
        let(:value_definition) do
          FactoryBot.create(:v2_value_definition, value_type: 'string', security_guide: item.security_guide)
        end

        let(:value_overrides) { { value_definition.id => 'foo' } }

        it 'updates value_overrides' do
          patch :update, params: params

          expect(response).to have_http_status :accepted
          expect(item.reload.value_overrides).to eq(value_overrides)
        end
      end

      context 'empty list of value overrides' do
        let(:value_overrides) { {} }

        it 'updates value_overrides' do
          patch :update, params: params

          expect(response).to have_http_status :accepted
          expect(item.reload.value_overrides).to be_empty
        end
      end

      context 'non-number value for a numeric value definition' do
        let(:value_definition) do
          FactoryBot.create(:v2_value_definition, value_type: 'number', security_guide: item.security_guide)
        end

        let(:value_overrides) { { value_definition.id => 'foo' } }

        it 'returns with not_acceptable' do
          patch :update, params: params

          expect(response).to have_http_status :not_acceptable
        end
      end

      context 'non-boolean value for a boolean value definition' do
        let(:value_definition) do
          FactoryBot.create(:v2_value_definition, value_type: 'boolean', security_guide: item.security_guide)
        end

        let(:value_overrides) { { value_definition.id => 'foo' } }

        it 'returns with not_acceptable' do
          patch :update, params: params

          expect(response).to have_http_status :not_acceptable
        end
      end
    end
  end

  context '/policies/:id/tailorings/:id/tailoring_file' do
    RSpec.shared_examples 'tailoring_file' do
      let(:parent) do
        FactoryBot.create(
          :v2_policy,
          :for_tailoring,
          account: current_user.account,
          supports_minors: [8]
        )
      end

      let(:extra_params) { { policy_id: parent.id, id: item.id } }

      context 'with no tailored rules and no values' do
        let(:item) do
          FactoryBot.create(
            :v2_tailoring,
            :without_rules,
            value_overrides: {}, # no tailored values
            policy: parent,
            os_minor_version: 8
          )
        end

        it 'returns tailoring file with unselected rules' do
          get :tailoring_file, params: extra_params.merge(parents: [:policy], format: format)

          expect(response).to have_http_status :ok
          expect(values).to be_empty
          expect(selected_rules).to be_empty
          expect(deselected_rules).not_to be_empty
          expect(deselected_rules).to match_array(item.profile.rules.map(&:ref_id))
        end
      end

      context 'with default, no unselected, rules and values' do
        let(:item) do
          FactoryBot.create(:v2_tailoring, policy: parent, os_minor_version: 8)
        end

        it 'returns empty response' do
          get :tailoring_file, params: extra_params.merge(parents: [:policy], format: format)

          expect(response).to have_http_status :no_content
        end
      end

      context 'with no tailored rules, but tailored values' do
        let(:item) do
          FactoryBot.create(:v2_tailoring, :without_rules, :with_tailored_values, policy: parent, os_minor_version: 8)
        end

        it 'returns tailored values and default set of rules, but unselected' do
          get :tailoring_file, params: extra_params.merge(parents: [:policy], format: format)

          expect(response).to have_http_status :ok
          expect(selected_rules).to be_empty
          expect(deselected_rules).not_to be_empty
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
            :with_mixed_rules, # tailor random rules
            :with_tailored_values, # tailor random values
            policy: parent,
            profile: canonical_profile,
            os_minor_version: 8
          )
        end

        it 'returns tailoring file' do
          get :tailoring_file, params: extra_params.merge(parents: [:policy], format: format)

          expect(response).to have_http_status :ok
          expect(response.headers['Content-Type']).to eq(Mime[format].to_s)
          expect(values).to match_array(item.value_overrides_by_ref_id)
          expect(selected_rules).not_to be_empty
          expect(selected_rules).to match_array(item.rules_added.map(&:ref_id))
          expect(groups).to match_array(item.rule_group_ref_ids)
        end
      end

      context 'with unauthorized policy' do
        let(:extra_params) do
          {
            # policy of a foreign account
            policy_id: FactoryBot.create(:v2_policy, account: FactoryBot.create(:v2_account)),
            id: item.id
          }
        end

        let(:item) { FactoryBot.create(:v2_tailoring, policy: parent, os_minor_version: 8) }

        it 'results in 404 error' do
          get :tailoring_file, params: extra_params.merge(parents: [:policy], format: format)

          expect(response).to have_http_status :not_found
        end
      end

      context 'with mismatching set of IDs' do
        let(:extra_params) do
          {
            policy_id: FactoryBot.create(:v2_policy, account: FactoryBot.create(:v2_account)),
            id: Faker::Internet.uuid
          }
        end

        it 'results in 404 error' do
          get :tailoring_file, params: extra_params.merge(parents: [:policy], format: format)

          expect(response).to have_http_status :not_found
        end
      end
    end

    context 'XCCDF' do
      let(:format) { :xml }
      let(:tailoring_file) { Nokogiri::XML(response.body).remove_namespaces! }

      let(:groups) do
        tailoring_file.xpath(
          '//Profile/select[starts-with(@idref, "xccdf_org.ssgproject.content_rule_group")]/@idref'
        ).map(&:value)
      end

      let(:selected_rules) do
        tailoring_file.xpath(
          '//Profile/select[
              starts-with(
                @idref, "xccdf_org.ssgproject.content_rule_"
              ) and not(contains(@idref, "rule_group"))
           ][@selected="true"]/@idref'
        ).map(&:value)
      end

      let(:deselected_rules) do
        tailoring_file.xpath(
          '//Profile/select[
              starts-with(
                @idref, "xccdf_org.ssgproject.content_rule_"
              ) and not(contains(@idref, "rule_group"))
           ][@selected="false"]/@idref'
        ).map(&:value)
      end

      let(:values) do
        tailoring_file.xpath('//Profile/set-value').each_with_object({}) do |value, obj|
          obj[value.attributes['idref'].value] = value.children.text
        end
      end

      context 'via CERT_AUTH' do
        before { allow(controller).to receive(:any_inventory_hosts?).and_return(true) }

        let(:current_user) { FactoryBot.create(:v2_user, :with_cert_auth) }

        include_examples 'tailoring_file'
      end

      include_examples 'tailoring_file'
    end

    context 'JSON' do
      let(:format) { :json }
      let(:tailoring_file) { response.parsed_body }
      let(:groups) { tailoring_file['profiles'].first['groups'].keys }
      let(:selected_rules) { tailoring_file['profiles'].first['rules'].select { |_, v| v['evaluate'] == true }.keys }
      let(:deselected_rules) { tailoring_file['profiles'].first['rules'].select { |_, v| v['evaluate'] == false }.keys }
      let(:values) { tailoring_file['profiles'].first['variables'].transform_values { |value| value['value'] } }

      context 'via CERT_AUTH' do
        before { allow(controller).to receive(:any_inventory_hosts?).and_return(true) }

        let(:current_user) { FactoryBot.create(:v2_user, :with_cert_auth) }

        include_examples 'tailoring_file'
      end

      include_examples 'tailoring_file'
    end

    context 'TOML' do
      let(:format) { :toml }
      let(:tailoring_file) { TOML.load(response.body) }
      let(:extra_params) { { policy_id: parent.id, id: item.id } }

      let(:parent) do
        FactoryBot.create(
          :v2_policy,
          :for_tailoring,
          account: current_user.account,
          supports_minors: [8]
        )
      end

      let(:item) do
        FactoryBot.create(
          :v2_tailoring,
          :with_mixed_rules,
          value_overrides: {}, # no tailored values
          policy: parent,
          os_minor_version: 8
        )
      end

      it 'returns tailoring_file' do
        FactoryBot.create(
          :fix,
          rule: item.rules.sample,
          system: V2::Fix::BLUEPRINT,
          text: "foo = \"bar\"\n"
        )

        get :tailoring_file, params: extra_params.merge(parents: [:policy], format: format)

        expect(response).to have_http_status :ok
        expect(tailoring_file).not_to be_empty
      end
    end
  end

  context '/policies/:id/tailorings/:id/migrations' do
    describe 'GET migrations' do
      let(:canonical_profile) do
        FactoryBot.create(
          :v2_profile,
          security_guide: FactoryBot.create(:v2_security_guide, rule_count: 5, os_major_version: 9),
          ref_id_suffix: 'foo',
          supports_minors: [6, 7, 8],
          rule_count: 5
        )
      end
      let(:parent) { FactoryBot.create(:v2_policy, account: current_user.account, profile: canonical_profile) }
      let!(:source_tailoring) do
        FactoryBot.create(
          :v2_tailoring,
          policy: parent,
          profile: canonical_profile,
          os_minor_version: 7
        )
      end
      let(:extra_params) do
        {
          policy_id: parent.id,
          id: source_tailoring.id,
          parents: [:policy],
          target_os_minor: 8
        }
      end

      context 'comparing tailorings with canonical rulesets' do
        it 'returns comparison' do
          get :compare, params: extra_params

          expect(response).to have_http_status :ok

          comparison_result = response.parsed_body
          expect(comparison_result).to be_an(Array)
          expect(comparison_result).not_to be_empty

          comparison_result.each do |rule|
            expect(rule).to have_key('available_in_versions')
            expect(rule['available_in_versions']).to be_an(Array)
            expect(rule['available_in_versions'].length).to eq(2)

            versions = rule['available_in_versions']
            expect(versions.map { |v| v['os_minor_version'] }).to contain_exactly(7, 8)
            expect(versions.all? { |v| v.key?('os_major_version') }).to be(true)
            expect(versions.all? { |v| v.key?('ssg_version') }).to be(true)
          end
        end
      end

      context 'comparing tailorings with mixed and canonical rules' do
        it 'returns comparison' do
          source_tailoring_mixed = FactoryBot.create(
            :v2_tailoring,
            :with_mixed_rules,
            policy: parent,
            profile: canonical_profile,
            os_minor_version: 6
          )

          mixed_params = extra_params.merge(id: source_tailoring_mixed.id)
          get :compare, params: mixed_params

          expect(response).to have_http_status :ok

          comparison_result = response.parsed_body
          expect(comparison_result).to be_an(Array)
          expect(comparison_result).not_to be_empty

          single_version_rules = comparison_result.select { |rule| rule['available_in_versions'].length == 1 }
          dual_version_rules = comparison_result.select { |rule| rule['available_in_versions'].length == 2 }

          expect(single_version_rules).not_to be_empty
          expect(dual_version_rules).not_to be_empty

          single_version_rules.each do |rule|
            version = rule['available_in_versions'].first
            expect([6, 8]).to include(version['os_minor_version'])
            expect(version).to have_key('os_major_version')
            expect(version).to have_key('ssg_version')
          end

          dual_version_rules.each do |rule|
            versions = rule['available_in_versions']
            expect(versions.map { |v| v['os_minor_version'] }).to contain_exactly(6, 8)
          end
        end

        it 'returns only the difference between the two tailorings' do
          get :compare, params: extra_params.merge(diff_only: true)

          comparison_result = response.parsed_body
          expect(comparison_result).to be_an(Array)
          expect(comparison_result).not_to be_empty

          single_version_rules = comparison_result.select { |rule| rule['available_in_versions'].length == 1 }
          dual_version_rules = comparison_result.select { |rule| rule['available_in_versions'].length == 2 }

          expect(single_version_rules).not_to be_empty
          expect(dual_version_rules).to be_empty
        end

        it 'includes all required rule attributes in the response' do
          get :compare, params: extra_params

          comparison_result = response.parsed_body
          comparison_result.map do |rule|
            expect(rule).to have_key('id')
            expect(rule).to have_key('ref_id')
            expect(rule).to have_key('title')
            expect(rule).to have_key('available_in_versions')
          end
        end
      end

      context 'invalid target os minor version' do
        it 'returns not found when the os minor version is not supported' do
          get :compare, params: extra_params.merge(target_os_minor_version: 9)

          expect(response).to have_http_status :not_found
          expect(response.parsed_body).to have_key('errors')
          expect(response.parsed_body['errors']).to include(
            "Profile does not support OS version #{canonical_profile.security_guide.os_major_version}.9"
          )
        end

        it 'returns unprocessable entity when the target version is lower than the source version' do
          get :compare, params: extra_params.merge(target_os_minor_version: 5)

          expect(response).to have_http_status :unprocessable_entity
          expect(response.parsed_body).to have_key('errors')
          expect(response.parsed_body['errors']).to include(
            'Target version 5 is lower than source version 7'
          )
        end
      end
    end
  end
end
