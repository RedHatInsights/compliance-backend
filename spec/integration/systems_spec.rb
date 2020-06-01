# frozen_string_literal: true

require 'swagger_helper'

describe 'Systems API' do
  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/systems" do
    get 'List all hosts' do
      fixtures :hosts
      tags 'host'
      description 'Lists all hosts requested'
      operationId 'ListHosts'

      content_types
      auth_header
      pagination_params
      search_params

      response '200', 'lists all hosts requested' do
        let(:'X-RH-IDENTITY') { encoded_header }
        schema type: :object,
               properties: {
                 meta: { '$ref' => '#/components/schemas/metadata' },
                 links: { '$ref' => '#/components/schemas/links' },
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: { type: :string, format: :uuid },
                       attributes: { '$ref' => '#/components/schemas/host' }
                     }
                   }
                 }
               }
        examples 'application/vnd.api+json' => {
          data: [
            {
              type: 'Host',
              id: 'd9654ad0-7cb5-4f61-b57c-0d22e3341dcc',
              attributes: {
                name: 'Standard System Security Profile for Fedora',
                ref_id: 'xccdf_org.ssgproject.content_host_standard'
              }
            }
          ]
        }
        run_test!
      end
    end
  end
end
