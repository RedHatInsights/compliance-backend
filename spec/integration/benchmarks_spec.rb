# frozen_string_literal: true

require 'swagger_helper'

describe 'Benchmarks API' do
  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/benchmarks" do
    get 'List all benchmarks' do
      fixtures :benchmarks
      tags 'benchmark'
      description 'Lists all benchmarks requested'
      operationId 'ListBenchmarks'

      content_types
      auth_header
      pagination_params
      search_params

      response '200', 'lists all benchmarks requested' do
        let(:'X-RH-IDENTITY') { encoded_header }
        schema type: :object,
               properties: {
                 meta: { '$ref' => '#/definitions/metadata' },
                 links: { '$ref' => '#/definitions/links' },
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: { type: :string, format: :uuid },
                       attributes: { '$ref' => '#/definitions/benchmark' }
                     }
                   }
                 }
               }
        examples 'application/vnd.api+json' => {
          meta: { filter:
                  'ref_id=xccdf_org.ssgproject.content_benchmark_RHEL-7' },
          data: [
            {
              type: 'benchmark',
              id: '1b743185-361a-4b9a-bf48-a8efd7114093',
              attributes: {
                description: 'This guide presents ... which provides required '\
                             'settings for US Department of Defense systems, '\
                             'is one example of a baseline created from '\
                             'this guidance.',
                ref_id: 'xccdf_org.ssgproject.content_benchmark_RHEL-7',
                title: 'Guide to the Secure Configuration of Red Hat '\
                       'Enterprise Linux 7',
                version: '0.1.46'
              }
            }
          ]
        }
        run_test!
      end
    end
  end

  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/benchmarks/{id}" do
    get 'Retrieve a benchmark' do
      fixtures :benchmarks
      tags 'benchmark'
      description 'Retrieves data for a benchmark'
      operationId 'ShowBenchmark'

      content_types
      auth_header
      pagination_params
      search_params

      parameter name: :id, in: :path, type: :string

      response '404', 'benchmark not found' do
        let(:id) { 'invalid' }
        let(:'X-RH-IDENTITY') { encoded_header }
        examples 'application/vnd.api+json' => {
          errors: 'Resource not found'
        }
        run_test!
      end

      response '200', 'retrieves a benchmark' do
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:id) { benchmarks(:one).id }
        schema type: :object,
               properties: {
                 meta: { '$ref' => '#/definitions/metadata' },
                 links: { '$ref' => '#/definitions/links' },
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: { type: :string, format: :uuid },
                     attributes: { '$ref' => '#/definitions/benchmark' }
                   }
                 }
               }
        examples 'application/vnd.api+json' => {
          data: {
            type: 'benchmark',
            id: 'd9654ad0-7cb5-4f61-b57c-0d22e3341dcc',
            attributes: {
              description: 'This guide presents ... which provides required '\
                           'settings for US Department of Defense systems, '\
                           'is one example of a baseline created from '\
                           'this guidance.',
              ref_id: 'xccdf_org.ssgproject.content_benchmark_RHEL-7',
              title: 'Guide to the Secure Configuration of Red Hat '\
                     'Enterprise Linux 7',
              version: '0.1.46'
            }
          }
        }

        run_test!
      end
    end
  end
end
