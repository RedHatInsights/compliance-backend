# frozen_string_literal: true

require 'swagger_helper'

describe 'Benchmarks API', swagger_doc: 'v1/openapi.json' do
  before do
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
  end

  path '/benchmarks' do
    get 'List all benchmarks' do
      before do
        account = FactoryBot.create(:account)
        profile = FactoryBot.create(
          :profile,
          :with_rules,
          rule_count: 2,
          name: 'Profile name with rules #1',
          account: account
        )

        FactoryBot.create(
          :profile,
          :with_rules,
          rule_count: 2,
          name: 'Profile name with rules #2',
          account: account
        )
        host = FactoryBot.create(
          :host,
          account: account.account_number,
          org_id: account.org_id
        )
        FactoryBot.create(:test_result, profile: profile, host: host)
      end

      tags 'benchmark'
      description 'Lists all benchmarks requested'
      operationId 'ListBenchmarks'

      content_types
      auth_header
      pagination_params
      search_params
      sort_params(Xccdf::Benchmark)

      include_param

      response '200', 'lists all benchmarks requested' do
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:include) { '' } # work around buggy rswag
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
                       attributes: ref_schema('benchmark'),
                       relationships: ref_schema('benchmark_relationships')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end

  path '/benchmarks/{id}' do
    get 'Retrieve a benchmark' do
      before do
        @profile = FactoryBot.create(:canonical_profile, :with_rules, name: 'First related profile')
        FactoryBot.create(
          :canonical_profile,
          :with_rules,
          name: 'Second related profile',
          benchmark_id: @profile.benchmark_id
        )

        group = FactoryBot.create(:rule_group, benchmark: @profile.benchmark)
        @profile.benchmark.rules.each do |rule|
          FactoryBot.create(:rule_group_rule, rule: rule, rule_group: group)
        end
      end

      tags 'benchmark'
      description 'Retrieves data for a benchmark'
      operationId 'ShowBenchmark'

      content_types
      auth_header

      parameter name: :id, in: :path, type: :string
      include_param

      response '404', 'benchmark not found' do
        let(:id) { 'invalid' }
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:include) { '' } # work around buggy rswag

        after { |e| autogenerate_examples(e) }

        run_test!
      end

      response '200', 'retrieves a benchmark' do
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:id) { @profile.benchmark.id }
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
                     attributes: ref_schema('benchmark'),
                     relationships: ref_schema('benchmark_relationships')
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end
end
