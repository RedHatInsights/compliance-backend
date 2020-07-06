# frozen_string_literal: true

require 'swagger_helper'

describe 'Systems API' do
  fixtures :accounts, :hosts
  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/systems" do
    get 'List all hosts' do
      tags 'host'
      description 'Lists all hosts requested'
      operationId 'ListHosts'

      content_types
      auth_header
      pagination_params
      search_params

      include_param

      response '200', 'lists all hosts requested' do
        let(:'X-RH-IDENTITY') { encoded_header(accounts(:one)) }
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
end
