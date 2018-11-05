# frozen_string_literal: true

require 'swagger_helper'

describe 'Profiles API' do
  path '/profiles' do
    get 'List all profiles' do
      fixtures :profiles
      tags 'profile'
      description 'Lists all profiles requested'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'

      response '200', 'lists all profiles requested' do
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
