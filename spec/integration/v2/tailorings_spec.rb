# frozen_string_literal: true

require 'swagger_helper'

describe 'Tailorings', swagger_doc: 'v2/openapi.json' do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:'X-RH-IDENTITY') { user.account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/policies/{policy_id}/tailorings' do
    let(:canonical_profiles) do
      25.times.map do |version|
        FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [version])
      end
    end

    let(:policy_id) do
      FactoryBot.create(
        :v2_policy,
        account: user.account,
        profile: canonical_profiles.last
      ).id
    end

    before do
      25.times.map do |version|
        FactoryBot.create(
          :v2_tailoring,
          policy: V2::Policy.find(policy_id),
          os_minor_version: version
        )
      end
    end

    get 'Request Tailorings' do
      v2_auth_header
      tags 'Policies'
      description 'Lists Tailorings'
      operationId 'Tailorings'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Tailoring)
      search_params_v2(V2::Tailoring)

      parameter name: :policy_id, in: :path, type: :string, required: true

      response '200', 'Lists Tailorings' do
        v2_collection_schema 'tailoring'

        after { |e| autogenerate_examples(e, 'List of Tailorings') }

        run_test!
      end

      response '200', 'Lists Tailorings' do
        let(:sort_by) { ['os_minor_version'] }
        v2_collection_schema 'tailoring'

        after { |e| autogenerate_examples(e, 'List of Tailorings sorted by "os_minor_version:asc"') }

        run_test!
      end

      response '200', 'Lists Tailorings' do
        let(:version) { V2::Tailoring.first.os_minor_version }
        let(:filter) { "(os_minor_version=#{version})" }
        v2_collection_schema 'tailoring'

        after { |e| autogenerate_examples(e, "List of Tailorings filtered by '(os_minor_version=#{version})'") }

        run_test!
      end

      response '422', 'Returns with Unprocessable Content' do
        let(:sort_by) { ['description'] }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when sorting by incorrect parameter') }

        run_test!
      end

      response '422', 'Returns with Unprocessable Content' do
        let(:limit) { 103 }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting higher limit than supported') }

        run_test!
      end
    end
  end

  path '/policies/{policy_id}/tailorings/{id}' do
    let(:policy_id) do
      FactoryBot.create(
        :v2_policy,
        account: user.account,
        profile: FactoryBot.create(:v2_profile, ref_id_suffix: 'foo', supports_minors: [1])
      ).id
    end

    let(:item) do
      FactoryBot.create(:v2_tailoring, policy: V2::Policy.find(policy_id), os_minor_version: 1)
    end

    get 'Request a Tailoring' do
      v2_auth_header
      tags 'Policies'
      description 'Returns a Tailoring'
      operationId 'Tailoring'
      content_types

      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Tailoring' do
        let(:id) { item.id }
        v2_item_schema('tailoring')

        after { |e| autogenerate_examples(e, 'Returns a Tailoring') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:id) { Faker::Internet.uuid }
        let(:policy_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after { |e| autogenerate_examples(e, 'Description of an error when requesting a non-existing Tailoring') }

        run_test!
      end
    end
  end

  path '/policies/{policy_id}/tailorings/{id}/tailoring_file.json' do
    let(:policy_id) do
      FactoryBot.create(:v2_policy, :for_tailoring, account: user.account, supports_minors: [1]).id
    end

    before { allow(StrongerParameters::InvalidValue).to receive(:new) { |value, _| value.to_sym } }

    let(:item) do
      FactoryBot.create(
        :v2_tailoring,
        :with_mixed_rules,
        :with_tailored_values,
        policy: V2::Policy.find(policy_id),
        os_minor_version: 1
      )
    end

    get 'Request a Tailoring file' do
      v2_auth_header
      tags 'Policies'
      description 'Returns a Tailoring File'
      operationId 'TailoringFile'
      content_types

      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Tailoring File' do
        let(:id) { item.id }
        schema ref_schema('tailoring_file')

        after { |e| autogenerate_examples(e, 'Returns a Tailoring File') }

        run_test!
      end
    end
  end
end
