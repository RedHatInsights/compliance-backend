# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require './spec/api/v1/openapi'
require './spec/api/v1/schemas/util'

include Api::V1::Schemas::Util # rubocop:disable Style/MixinUsage

RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'

  config.before(:each) do
    stub_request(:get, /#{Settings.endpoints.rbac_url}/)
      .to_return(status: 200,
                 body: { 'data': [{ 'permission': 'compliance:*:*' }] }.to_json)
    stub_request(:get, /#{Settings.private_endpoints.compliance_ssg.url}/).to_return(status: 404)
  end

  config.swagger_docs = {
    'v1/openapi.json' => Api::V1::Openapi.doc
  }
end

def autogenerate_examples(example, label = 'Response example', summary = '', description = '')
  content = example.metadata[:response][:content] || {}
  body = JSON.parse(response.body, symbolize_names: true)
  example_obj = { "#{label}": { value: body, summary: summary, description: description } }
  example.metadata[:response][:content] = content.deep_merge(
    {
      'application/vnd.api+json': {
        examples: example_obj
      }
    }
  )
end

def encoded_header(account = nil)
  Base64.strict_encode64(x_rh_identity(account).to_json)
end

# Justification: It's mostly hash test data
# rubocop:disable Metrics/MethodLength
def x_rh_identity(account = nil)
  {
    'identity':
    {
      'org_id': account&.org_id || '1234',
      'type': 'User',
      'user': {
        'email': 'a@b.com',
        'username': 'a@b.com',
        'first_name': 'a',
        'last_name': 'b',
        'is_active': true,
        'locale': 'en_US'
      },
      'internal': {
        'org_id': '29329'
      }
    },
    'entitlements':
      {
        'insights': {
          'is_entitled': true
        }
      }
  }.with_indifferent_access
end
# rubocop:enable Metrics/MethodLength

def include_param
  parameter name: :include, in: :query, required: false,
            schema: { type: :string },
            description: 'A comma seperated list of resources to include in '\
                         'the response'
end

def pagination_params
  parameter name: :limit, in: :query, required: false,
            description: 'The number of items to return',
            schema: { type: :integer, maximum: 100, minimum: 1, default: 10 }
  parameter name: :offset, in: :query, required: false,
            description: 'The number of items to skip before starting '\
            'to collect the result set',
            schema: { type: :integer, minimum: 1, default: 1 }
end

def search_params
  parameter name: :search, in: :query, required: false,
            description: 'Query string compliant with scoped_search '\
            'query language: '\
            'https://github.com/wvanbergen/scoped_search/wiki/Query-language',
            schema: { type: :string, default: '' }
end

def tags_params
  parameter name: :tags, in: :query, required: false,
            description: 'An array of tags to narrow down the results against. ' \
            'The namespace, key and value are concatenated using `/` and `=` symbols. ' \
            'In case the values contain symbols used for separators, `/` is replaced with `%2F`, ' \
            '`=` is replaced with `%3D`.<br><br>' \
            'e.g.: `namespace/key=value`, `insights-client/selinux-config=SELINUX%3Denforcing`',
            schema: { type: :array, items: { type: 'string' }, default: '' }
end

def sort_params(model = nil)
  parameter name: :sort_by, in: :query, required: false,
            description: 'An array of fields with an optional direction '\
             '(:asc or :desc) to sort the results.',
            schema: {
              type: :string,
              items: { enum: sort_combinations(model) },
              default: ''
            }
end

def sort_combinations(model)
  fields = model.instance_variable_get(:@sortable_by).keys
  fields + fields.flat_map do |field|
    %w[asc desc].map do |direction|
      [field, direction].join(':')
    end
  end
end

def content_types
  # HACK: the argument is passed as a symbol to avoid being duplicated.
  # Possibly an rswag issue.
  # (see https://github.com/rswag/rswag/blob/8399d508f46492b0baa2d72e63f8260ecd9a737f/rswag-specs/lib/rswag/specs/swagger_formatter.rb#L151)
  consumes :'application/vnd.api+json'
  produces :'application/vnd.api+json'
end

def auth_header
  parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string }
end
