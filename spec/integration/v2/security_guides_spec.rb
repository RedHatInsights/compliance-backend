# frozen_string_literal: true

require 'swagger_helper'

describe 'Security Guides', swagger_doc: 'v2/openapi.json' do
  let(:identity_header) do
    OpenStruct.new(
      cert_based?: false,
      valid?: true,
      org_id: '1234',
      identity: { org_id: '1234' },
      raw: nil
    )
  end
  let!(:security_guides) do
    SupportedSsg.all.map(&:os_major_version).uniq.map do |os_version|
      FactoryBot.create(
        :v2_security_guide,
        title: 'Guide to the Secure Configuration of Red Hat Enterprise ' \
               "Linux #{os_version}",
        description: 'This guide presents a catalog of security-relevant ' \
                     "configuration settings for Red Hat Enterprise Linux #{os_version}.",
        os_major_version: os_version
      )
    end
  end
  let(:sg_id) { security_guides.first.id }

  before do
    allow(Insights::Api::Common::IdentityHeader).to receive(:new).and_return(identity_header)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  path '/security_guides' do
    get 'List all Security Guides' do
      tags 'security_guide'
      description 'Lists all Security guides'
      operationId 'ListSecurityGuides'
      content_types
      pagination_params_v2
      sort_params_v2(V2::SecurityGuide)
      search_params_v2(V2::SecurityGuide)

      response '200', 'Lists all Security Guides requested' do
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
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Security Guides') }

        run_test!
      end

      response '200', 'Lists all Security Guides requested' do
        let(:sort_by) { ['os_major_version'] }
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
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Security Guides sorted by "os_major_verision:asc"') }

        run_test!
      end

      response '200', 'Lists all Security Guides requested' do
        let(:filter) { '(os_major_version=8)' }
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
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'List of Security Guides filtered by "(os_major_version=8)"') }

        run_test!
      end

      response '422', 'Returns error if wrong parameters are used' do
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
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when sorting by incorrect parameter') }

        run_test!
      end

      response '422', 'Returns error if wrong parameters are used' do
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
                       attributes: ref_schema('security_guides')
                     }
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Description of an error when requesting higher limit than supported') }

        run_test!
      end
    end
  end

  path '/security_guides/{sg_id}' do
    get 'Returns requested Security Guide' do
      tags 'security_guide'
      description 'Returns requested Security Guide'
      operationId 'ShowSecurityGuide'
      content_types
      parameter name: :sg_id, in: :path, type: :string, required: true

      response '200', 'Returns requested Security Guide' do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: ref_schema('id'),
                     attributes: ref_schema('security_guide')
                   }
                 }
               }

        after { |e| autogenerate_examples(e, 'Security Guide') }

        run_test!
      end

      response '404', 'Security Guide not found' do
        let(:sg_id) { Faker::Internet.uuid }

        after do |e|
          autogenerate_examples(e, 'Description of an error when the requested Security Guide is not found')
        end

        run_test!
      end
    end
  end
end
