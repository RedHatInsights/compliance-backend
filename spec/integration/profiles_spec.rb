# frozen_string_literal: true

require 'swagger_helper'

describe 'Profiles API' do
  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/profiles" do
    get 'List all profiles' do
      fixtures :profiles
      tags 'profile'
      description 'Lists all profiles requested'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      operationId 'ListProfiles'
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

  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/profiles/{id}" do
    get 'Retrieve a profile' do
      fixtures :profiles
      tags 'profile'
      description 'Retrieves data for a profile'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      operationId 'ShowProfile'
      parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string }
      parameter name: :id, in: :path, type: :string

      response '404', 'profile not found' do
        let(:id) { 'invalid' }
        let(:'X-RH-IDENTITY') { encoded_header }
        examples 'application/vnd.api+json' => {
          errors: 'Resource not found'
        }
        run_test!
      end

      response '200', 'retrieves a profile' do
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:id) do
          Account.create(
            account_number: x_rh_identity[:identity][:account_number]
          )
          user = User.from_x_rh_identity(x_rh_identity[:identity])
          user.save
          profiles(:one).update(account: user.account)
          profiles(:one).id
        end
        schema type: :object,
               properties: {
                 meta: { '$ref' => '#/definitions/metadata' },
                 links: { '$ref' => '#/definitions/links' },
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: { type: :string, format: :uuid },
                     attributes: { '$ref' => '#/definitions/profile' }
                   }
                 }
               }
        examples 'application/vnd.api+json' => {
          data: {
            type: 'Profile',
            id: 'd9654ad0-7cb5-4f61-b57c-0d22e3341dcc',
            attributes: {
              name: 'Standard System Security Profile for Fedora',
              ref_id: 'xccdf_org.ssgproject.content_profile_standard',
              description: 'Set of rules for Fedora',
              score: 1,
              total_host_count: 1,
              compliant_host_count: 1
            }
          }
        }

        run_test!
      end
    end
  end
end
