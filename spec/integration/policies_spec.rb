# frozen_string_literal: true

require 'swagger_helper'

describe 'Policies', swagger_doc: 'v2/openapi.json' do
  let(:identity_header) do
    OpenStruct.new(
      id: Faker::Internet.uuid,
      cert_based?: false,
      valid?: true,
      org_id: '1234',
      identity: { org_id: '1234' },
      raw: nil
    )
  end

  let(:account) { FactoryBot.create(:v2_account) }
  let(:user) { FactoryBot.create(:v2_user, account: account) }
  let!(:policies) do
    FactoryBot.create_list(:v2_policy, 4, account: account)
  end
  let(:valid_policy_id) { policies.first.id }
  let(:policy_id) { valid_policy_id }

  before do
    allow(Insights::Api::Common::IdentityHeader).to receive(:new).and_return(user.account.identity_header)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  path '/policies' do
    get 'List all Policies' do
      tags 'policy'
      description 'Lists all Policies'
      operationId 'ListPolicies'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Policy)
      search_params_v2(V2::Policy)

      response '200', 'lists all Policies requested' do
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('policy')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Policies') }

        run_test!
      end

      # TODO: this can be turned on after we have ways to assign hosts
      # response '200', 'lists all Policies requested' do
      #   let(:sort_by) { ['total_host_count'] }
      #   schema type: :object,
      #          properties: {
      #            meta: ref_schema('metadata'),
      #            links: ref_schema('links'),
      #            data: {
      #              type: :array,
      #              items: {
      #                properties: {
      #                  type: { type: :string },
      #                  id: ref_schema('id'),
      #                  attributes: ref_schema('policies')
      #                }
      #              }
      #            }
      #          }
      #
      #   after { |e| autogenerate_examples(e, 'List of Policies sorted by "total_host_count:asc"') }
      #
      #   run_test!
      # end

      # TODO: this needs to be made compatible with `expand_resource`
      # response '200', 'lists all Policies requested' do
      #   let(:filter) { '(os_major_version=8)' }
      #   schema type: :object,
      #          properties: {
      #            meta: ref_schema('metadata'),
      #            links: ref_schema('links'),
      #            data: {
      #              type: :array,
      #              items: {
      #                properties: {
      #                  type: { type: :string },
      #                  id: ref_schema('id'),
      #                  attributes: ref_schema('policies')
      #                }
      #              }
      #            }
      #          }
      #
      #   after { |e| autogenerate_examples(e, 'List of Policies filtered by "(os_major_version=8)"') }
      #
      #   run_test!
      # end

      response '422', 'returns error if wrong parameters are used' do
        let(:sort_by) { ['description'] }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('policies')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when sorting by incorrect parameter') }

        run_test!
      end

      response '422', 'returns error if wrong parameters are used' do
        let(:limit) { 103 }
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('policies')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when requesting higher limit than supported') }

        run_test!
      end
    end
  end

  path '/policies/{policy_id}' do
    get 'Retrieve a Policy' do
      tags 'policy'
      description 'Retrieves requested Policy'
      operationId 'ShowPolicy'
      content_types
      parameter name: :policy_id, in: :path, type: :string, required: true

      response '200', 'retrieves a Policy' do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('id'),
                     attributes: ref_schema('policy')
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Policy') }

        run_test!
      end

      response '404', 'Policy not found' do
        let(:policy_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Policy is not found')
        end

        run_test!
      end
    end
  end

  let(:tailoring) { FactoryBot.create(:v2_tailoring, policy_id: policy_id) }
  let(:tailoring_id) { tailoring.id }

  path '/policies/{policy_id}/tailorings' do
    get 'List all Tailorings under Policy' do
      tags 'policy'
      description 'Lists all Tailorings under Policy'
      operationId 'ListTailorings'
      content_types
      pagination_params_v2
      sort_params_v2(V2::Tailoring)
      search_params_v2(V2::Tailoring)
      parameter name: :policy_id, in: :path, type: :string, required: true

      response '200', 'lists all Tailorings under Policy' do
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 links: ref_schema('links'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: ref_schema('id'),
                       attributes: ref_schema('tailoring')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Tailorings under Policy') }

        run_test!
      end
    end
  end

  path '/policies/{policy_id}/tailorings/{tailoring_id}' do
    get 'Retrieve Tailoring under Policy' do
      tags 'policy'
      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :tailoring_id, in: :path, type: :string, required: true

      response '200', 'retrieves a Tailoring under a Policy' do
        after { |e| autogenerate_examples(e, 'Tailoring under Policy') }

        run_test!
      end
    end
  end

  path '/policies/{policy_id}/tailorings/{tailoring_id}/tailoring_file' do
    get 'Retrieve XCCDF file of Tailoring under Policy' do
      parameter name: :policy_id, in: :path, type: :string, required: true
      parameter name: :tailoring_id, in: :path, type: :string, required: true

      response '200', 'generates XCCDF file of Tailoring under Policy' do
        after { |e| autogenerate_examples(e, 'XCCDF file of Tailoring under Policy') }

        run_test!
      end
    end
  end
end
