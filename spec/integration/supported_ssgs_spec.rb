# frozen_string_literal: true

require 'swagger_helper'

describe 'SupportedSsgs API' do
  fixtures :accounts

  path '/supported_ssgs' do
    get 'List all supported SSGs' do
      tags 'supported_ssg'
      description 'List all supported SSGs mapped to RHEL minor version'
      operationId 'ListSupportedSsgs'

      content_types
      auth_header

      include_param

      response '200', 'lists all supported_ssgs requested' do
        let(:'X-RH-IDENTITY') { encoded_header(accounts(:test)) }
        let(:include) { '' } # work around buggy rswag
        schema type: :object,
               properties: {
                 meta: ref_schema('metadata'),
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: { type: :string },
                       attributes: ref_schema('supported_ssg')
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
