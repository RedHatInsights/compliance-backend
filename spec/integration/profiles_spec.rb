# frozen_string_literal: true

require 'swagger_helper'
require 'sidekiq/testing'

describe 'Profiles API' do
  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/profiles" do
    get 'List all profiles' do
      fixtures :accounts, :hosts, :benchmarks, :profiles
      tags 'profile'
      description 'Lists all profiles requested'
      operationId 'ListProfiles'

      content_types
      auth_header
      pagination_params
      search_params

      response '200', 'lists all profiles requested' do
        before do
          profiles(:one).update!(account: accounts(:one))
        end

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
                       attributes: ref_schema('profile')
                     }
                   }
                 }
               }
        after { |e| autogenerate_examples(e) }
        run_test!
      end

      response '200', 'lists all profiles requested filtered by OS' do
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:include) { '' } # work around buggy rswag
        let(:search) { 'os_major_version = 7' }
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
                       attributes: ref_schema('profile')
                     }
                   }
                 }
               }
        after { |e| autogenerate_examples(e) }
        run_test!
      end
    end

    post 'Create a profile' do
      fixtures :accounts, :profiles, :benchmarks
      tags 'profile'
      description 'Create a profile with the provided attributes'
      operationId 'CreateProfile'

      content_types
      auth_header

      parameter name: :data, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              attributes: ref_schema('profile_create')
            }
          }
        }
      }

      response '201', 'creates a profile' do
        let(:'X-RH-IDENTITY') { encoded_header(accounts(:one)) }
        let(:include) { '' } # work around buggy rswag
        let(:data) do
          {
            data: {
              attributes: {
                parent_profile_id: profiles(:two).id,
                name: 'A custom name',
                compliance_threshold: 93.5,
                business_objective: 'LATAM Expansion'
              }
            }
          }
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('uuid'),
                     attributes: ref_schema('profile'),
                     relationships: ref_schema('profile_relationships')
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end

  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/profiles/{id}" do
    get 'Retrieve a profile' do
      fixtures :hosts, :benchmarks, :profiles
      tags 'profile'
      description 'Retrieves data for a profile'
      operationId 'ShowProfile'

      content_types
      auth_header

      parameter name: :id, in: :path, type: :string
      include_param

      response '404', 'profile not found' do
        let(:id) { 'invalid' }
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:include) { '' } # work around buggy rswag
        after { |e| autogenerate_examples(e) }
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
          profiles(:one).update(account: user.account, hosts: [hosts(:one)],
                                parent_profile_id: profiles(:two).id)
          profiles(:one).id
        end
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
                     attributes: ref_schema('profile'),
                     relationships: ref_schema('profile_relationships')
                   }
                 }
               }
        after { |e| autogenerate_examples(e) }

        run_test!
      end

      response '200', 'retrieves a profile with included benchmark' do
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:id) do
          Account.create(
            account_number: x_rh_identity[:identity][:account_number]
          )
          user = User.from_x_rh_identity(x_rh_identity[:identity])
          user.save
          profiles(:one).update(account: user.account, hosts: [hosts(:one)])
          profiles(:one).id
        end
        let(:include) { 'benchmark' }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('uuid'),
                     attributes: ref_schema('profile')
                   },
                   relationships: ref_schema('profile_relationships'),
                   included: {
                     type: :array,
                     items: {
                       type: :object,
                       properties: {
                         type: { type: :string },
                         id: ref_schema('uuid'),
                         attributes: ref_schema('benchmark')
                       }
                     }
                   }
                 }
               }
        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end

    delete 'Destroy a profile' do
      fixtures :accounts, :benchmarks, :profiles
      tags 'profile'
      description 'Destroys a profile'
      operationId 'DestroyProfile'

      content_types
      auth_header

      parameter name: :id, in: :path, type: :string
      include_param

      response '404', 'profile not found' do
        let(:id) { 'invalid' }
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:include) { '' } # work around buggy rswag

        after { |e| autogenerate_examples(e) }

        run_test!
      end

      response '202', 'destroys a profile' do
        before do
          profiles(:one).update!(account: accounts(:one))
        end

        let(:'X-RH-IDENTITY') { encoded_header(accounts(:one)) }
        let(:id) {
          profiles(:one).update(parent_profile_id: profiles(:two).id)
          profiles(:one).id
        }
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
                     attributes: ref_schema('profile'),
                     relationships: ref_schema('profile_relationships')
                   }
                 }
               }

        after { |e| autogenerate_examples(e) }

        run_test!
      end
    end
  end
end
