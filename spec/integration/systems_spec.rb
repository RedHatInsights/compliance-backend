# frozen_string_literal: true

require 'swagger_helper'

describe 'Systems API' do
  path '/api/compliance/systems' do
    get 'List all hosts' do
      fixtures :hosts
      tags 'host'
      description 'Lists all hosts requested'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string }

      response '200', 'lists all hosts requested' do
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
                       attributes: { '$ref' => '#/definitions/host' }
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
