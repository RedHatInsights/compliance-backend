# frozen_string_literal: true

require 'swagger_helper'

describe 'Rule Groups', swagger_doc: 'v2/openapi.json' do
  let(:'X-RH-IDENTITY') { FactoryBot.create(:v2_user).account.identity_header.raw }

  before { stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ) }

  path '/security_guides/{security_guide_id}/rule_groups' do
    before { FactoryBot.create_list(:v2_rule_group, 25, security_guide_id: security_guide_id) }

    let(:security_guide_id) { FactoryBot.create(:v2_security_guide).id }

    get 'Request Rule Groups' do
      v2_auth_header
      tags 'rule_groups'
      description 'Lists Rule Groups'
      operationId 'Rule Groups'
      content_types
      pagination_params_v2
      sort_params_v2(V2::RuleGroup)
      search_params_v2(V2::RuleGroup)

      parameter name: :security_guide_id, in: :path, type: :string, required: true

      response '200', 'Lists Rule Groups' do
        v2_collection_schema 'rule_group'

        after { |e| autogenerate_examples(e, 'List of Rule Groups') }

        run_test!
      end

      response '200', 'Lists Rule Groups' do
        let(:sort_by) { ['precedence'] }
        v2_collection_schema 'rule_group'

        after { |e| autogenerate_examples(e, 'List of Rule Groups sorted by "precedence:asc"') }

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

  path '/security_guides/{security_guide_id}/rule_groups/{id}' do
    let(:item) { FactoryBot.create(:v2_rule_group) }

    get 'Request a Rule Group' do
      v2_auth_header
      tags 'rule_groups'
      description 'Returns a Rule Group'
      operationId 'Rule Group'
      content_types

      parameter name: :security_guide_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Returns a Rule Group' do
        let(:id) { item.id }
        let(:security_guide_id) { item.security_guide.id }
        v2_item_schema('rule_group')

        after { |e| autogenerate_examples(e, 'Returns a Rule Group') }

        run_test!
      end

      response '404', 'Returns with Not Found' do
        let(:id) { Faker::Internet.uuid }
        let(:security_guide_id) { Faker::Internet.uuid }
        schema ref_schema('errors')

        after do |e|
          autogenerate_examples(e, 'Description of an error when requesting a non-existing Rule Group')
        end

        run_test!
      end
    end
  end
end
