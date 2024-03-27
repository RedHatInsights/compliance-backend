# frozen_string_literal: true

require 'swagger_helper'

describe 'Rules', swagger_doc: 'v2/openapi.json' do
  let(:user) { FactoryBot.create(:v2_user) }
  let(:'X-RH-IDENTITY') { user.account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/security_guides/{security_guide_id}/rules' do
    before { FactoryBot.create_list(:v2_rule, 25, security_guide_id: security_guide_id) }

    let(:security_guide_id) { FactoryBot.create(:v2_security_guide).id }

    get 'Request Rules' do
      v2_auth_header
      tags 'Content'
      description 'Lists Rules assigned'
      operationId 'Rules'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Rule)
      search_params_v2(V2::Rule)

      parameter name: :security_guide_id, in: :path, type: :string, required: true

      response '200', 'Lists Rules' do
        v2_collection_schema 'rule'

        after { |e| autogenerate_examples(e, 'List of Rules') }

        run_test!
      end

      response '200', 'Lists Rules' do
        let(:sort_by) { ['precedence'] }
        v2_collection_schema 'rule'

        after { |e| autogenerate_examples(e, 'List of Rules sorted by "precedence:asc"') }

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

  path '/security_guides/{security_guide_id}/rules/{id}' do
    let(:item) { FactoryBot.create(:v2_rule) }

    get 'Request a Rule' do
      v2_auth_header
      tags 'Content'
      description 'Returns a Rule'
      operationId 'Rule'
      content_types

      parameter name: :security_guide_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Rule' do
        let(:id) { item.id }
        let(:security_guide_id) { item.security_guide.id }
        v2_item_schema('rule')

        after { |e| autogenerate_examples(e, 'Returns a Rule') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:id) { Faker::Internet.uuid }
        let(:security_guide_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after do |e|
          autogenerate_examples(e, 'Description of an error when requesting a non-existing Rule')
        end

        run_test!
      end
    end
  end

  path '/security_guides/{security_guide_id}/profiles/{profile_id}/rules' do
    before { FactoryBot.create_list(:v2_rule, 25, security_guide_id: security_guide_id, profile_id: profile_id) }

    let(:security_guide_id) { FactoryBot.create(:v2_security_guide).id }
    let(:profile_id) { FactoryBot.create(:v2_profile, security_guide_id: security_guide_id).id }

    get 'Request Rules assigned to a Profile' do
      v2_auth_header
      tags 'Content'
      description 'Lists Rules assigned to a Profile'
      operationId 'ProfileRules'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Rule)
      search_params_v2(V2::Rule)

      parameter name: :security_guide_id, in: :path, type: :string, required: true
      parameter name: :profile_id, in: :path, type: :string, required: true

      response '200', 'Lists Rules assigned to a Profile' do
        v2_collection_schema 'rule'

        after { |e| autogenerate_examples(e, 'List of Rules') }

        run_test!
      end

      response '200', 'Lists Rules assigned to a Profile' do
        let(:sort_by) { ['precedence'] }
        v2_collection_schema 'rule'

        after { |e| autogenerate_examples(e, 'List of Rules sorted by "precedence:asc"') }

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

  path '/security_guides/{security_guide_id}/profiles/{profile_id}/rules/{id}' do
    let(:item) { FactoryBot.create(:v2_rule, profile_id: profile_id) }

    get 'Request a Rule assigned to a Profile' do
      v2_auth_header
      tags 'Content'
      description 'Returns a Rule assigned to a Profile'
      operationId 'ProfileRule'
      content_types

      parameter name: :security_guide_id, in: :path, type: :string, required: true
      parameter name: :profile_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Rule assigned to a Profile' do
        let(:security_guide_id) { V2::Profile.find(profile_id).security_guide_id }
        let(:profile_id) { FactoryBot.create(:v2_profile).id }
        let(:id) { item.id }

        v2_item_schema('rule')

        after { |e| autogenerate_examples(e, 'Returns a Rule') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:id) { Faker::Internet.uuid }
        let(:profile_id) { Faker::Internet.uuid }
        let(:security_guide_id) { Faker::Internet.uuid }

        schema ref_schema('errors')

        after do |e|
          autogenerate_examples(e, 'Description of an error when requesting a non-existing Rule')
        end

        run_test!
      end
    end
  end

  path '/policies/{policy_id}/tailorings/{tailoring_id}/rules' do
    before do
      FactoryBot.create(
        :v2_rule,
        security_guide: V2::Tailoring.find(tailoring_id).profile.security_guide,
        tailoring_id: tailoring_id
      )
    end

    let(:tailoring_id) do
      FactoryBot.create(
        :v2_tailoring,
        policy: V2::Policy.find(policy_id),
        os_minor_version: 9
      ).id
    end

    let(:policy_id) { FactoryBot.create(:v2_policy, account: user.account, supports_minors: [9]).id }

    get 'Request Rules assigned to a Tailoring' do
      v2_auth_header
      tags 'Policies'
      description 'Lists Rules assigned to a Tailoring'
      operationId 'TailoringRules'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Rule)
      search_params_v2(V2::Rule)

      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :tailoring_id, in: :path, type: :string, required: true

      response '200', 'Lists Rules assigned to a Tailoring' do
        v2_collection_schema 'rule'

        after { |e| autogenerate_examples(e, 'List of Rules') }

        run_test!
      end

      response '200', 'Lists Rules assigned to a Tailoring' do
        let(:sort_by) { ['precedence'] }
        v2_collection_schema 'rule'

        after { |e| autogenerate_examples(e, 'List of Rules sorted by "precedence:asc"') }

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

  path '/policies/{policy_id}/tailorings/{tailoring_id}/rules/{id}' do
    let(:tailoring_id) do
      FactoryBot.create(
        :v2_tailoring,
        policy: V2::Policy.find(policy_id),
        os_minor_version: 9
      ).id
    end

    let(:policy_id) { FactoryBot.create(:v2_policy, account: user.account, supports_minors: [9]).id }

    patch 'Assign a Rule to a Tailoring' do
      let(:item) do
        FactoryBot.create(:v2_rule, security_guide: V2::Tailoring.find(tailoring_id).profile.security_guide)
      end

      v2_auth_header
      tags 'Policies'
      description 'Assigns a Rule to a Tailoring'
      operationId 'AssignRule'
      content_types

      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :tailoring_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '202', 'Assigns a Rule to a Tailoring' do
        let(:id) { item.id }

        after { |e| autogenerate_examples(e, 'Assigns a Rule to a Tailoring') }

        run_test!
      end

      response '404', 'Returns with Not found' do
        let(:id) { Faker::Internet.uuid }

        after { |e| autogenerate_examples(e, 'Returns with Not found') }

        run_test!
      end
    end

    delete 'Unassign a Rule from a Tailoring' do
      let(:item) do
        FactoryBot.create(
          :v2_rule,
          security_guide: V2::Tailoring.find(tailoring_id).profile.security_guide,
          tailoring_id: tailoring_id
        )
      end

      v2_auth_header
      tags 'Policies'
      description 'Unassigns a Rule from a Tailoring'
      operationId 'UnassignRule'
      content_types

      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :tailoring_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '202', 'Unassigns a Rule from a Tailoring' do
        let(:id) { item.id }

        after { |e| autogenerate_examples(e, 'Unassigns a Rule from a Tailoring') }

        run_test!
      end

      response '404', 'Returns with Not found' do
        let(:id) { Faker::Internet.uuid }

        after { |e| autogenerate_examples(e, 'Description of an error when unassigning a non-existing Rule') }

        run_test!
      end
    end
  end
end
