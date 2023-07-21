# frozen_string_literal: true

require 'swagger_helper'

describe 'Systems API', swagger_doc: 'v1/openapi.json' do
  before do
    allow_any_instance_of(PolicyHost).to receive(:host_supported?).and_return true
    @account = FactoryBot.create(:account)
    @host = FactoryBot.create(
      :host,
      :with_groups,
      group_count: 1,
      insights_id: '45b7b025-4bf4-48a5-abbd-161c12ece8f4',
      org_id: @account.org_id,
      tags: [{ namespace: 'foo', key: 'bar', value: 'baz' }]
    )
    policy = FactoryBot.create(:policy, account: @account, hosts: [@host])
    profile = FactoryBot.create(
      :profile,
      :with_rules,
      account: @account,
      policy: policy,
      external: true
    )
    FactoryBot.create(:test_result, profile: profile, host: @host)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
  end

  path '/systems' do
    get 'List all hosts' do
      tags 'host'
      description 'Lists all hosts requested'
      operationId 'ListHosts'

      content_types
      auth_header
      pagination_params
      search_params
      tags_params
      sort_params(Host)

      include_param

      response '200', 'lists all hosts requested' do
        let(:'X-RH-IDENTITY') { encoded_header(@account) }
        let(:include) { '' } # work around buggy rswag
        let(:tags) { ['foo/bar=baz'] }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('uuid'),
                       attributes: ref_schema('host'),
                       relationships: ref_schema('host_relationships')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end

  path '/systems/{id}' do
    get 'Retrieve a system' do
      tags 'host'
      description 'Retrieves data for a system'
      operationId 'ShowHost'

      content_types
      auth_header

      parameter name: :id, in: :path, type: :string
      include_param

      response '404', 'system not found' do
        let(:id) { 'invalid' }
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:include) { '' } # work around buggy rswag
        after { |e| autogenerate_examples(e) }
        run_test!
      end

      response '200', 'retrieves a system' do
        let(:'X-RH-IDENTITY') { encoded_header(@account) }
        let(:id) { @host.id }
        let(:include) { '' } # work around buggy rswag
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('uuid'),
                     attributes: ref_schema('host'),
                     relationships: ref_schema('host_relationships')
                   }
                 }
               }
        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end
end
