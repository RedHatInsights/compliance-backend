# frozen_string_literal: true

require 'swagger_helper'

# Justification: It's mostly hash test data
# rubocop:disable Metrics/MethodLength
def encoded_header
  Base64.encode64(
    {
      'account_number': '1234',
      'id': '1234',
      'org_id': '29329',
      'email': 'a@b.com',
      'username': 'a@b.com',
      'first_name': 'a',
      'last_name': 'b',
      'is_active': true,
      'locale': 'en_US'
    }.to_json
  )
end
# rubocop:enable Metrics/MethodLength

describe 'Profiles API' do
  path '/profiles' do
    get 'List all profiles' do
      fixtures :profiles
      tags 'profile'
      description 'Lists all profiles requested'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string }

      response '200', 'lists all profiles requested' do
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
                       attributes: { '$ref' => '#/definitions/profile' }
                     }
                   }
                 }
               }
        examples 'application/vnd.api+json' => {
          meta: { filter: 'name=Standard System Security Profile for Fedora' },
          data: [
            {
              type: 'Profile',
              id: 'd9654ad0-7cb5-4f61-b57c-0d22e3341dcc',
              attributes: {
                name: 'Standard System Security Profile for Fedora',
                ref_id: 'xccdf_org.ssgproject.content_profile_standard'
              }
            }
          ]
        }
        run_test!
      end
    end
  end
end
