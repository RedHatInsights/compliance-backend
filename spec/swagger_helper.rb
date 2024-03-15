# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require './spec/api/v1/openapi'
require './spec/api/v1/schemas/util'
require './spec/api/v2/openapi'
# require './spec/api/v2/schemas/util'

include Api::V1::Schemas::Util # rubocop:disable Style/MixinUsage

RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'
  # FIXME: https://github.com/rswag/rswag/issues/666
  # config.swagger_strict_schema_validation = true
  config.before(:each) do
    stub_request(:get, /#{Settings.endpoints.rbac_url}/)
      .to_return(status: 200,
                 body: { 'data': [{ 'permission': 'compliance:*:*' }] }.to_json)
    stub_request(:get, /#{Settings.private_endpoints.compliance_ssg.url}/).to_return(status: 404)
  end

  config.swagger_docs = {
    'v1/openapi.json' => Api::V1::Openapi.doc,
    'v2/openapi.json' => Api::V2::Openapi.doc
  }

  config.after(:each, operation: true, use_as_request_example: true) do |spec|
    spec.metadata[:operation][:request_examples] ||= []

    example = {
      value: JSON.parse(request.body.string, symbolize_names: true),
      name: spec.metadata[:response][:description].parameterize.underscore,
      summary: spec.metadata[:response][:description]
    }

    spec.metadata[:operation][:request_examples] << example
  end
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
            description: 'A comma seperated list of resources to include in ' \
                         'the response'
end

def pagination_params
  parameter name: :limit, in: :query, required: false,
            description: 'The number of items to return',
            schema: { type: :integer, maximum: 100, minimum: 1, default: 10 }
  parameter name: :offset, in: :query, required: false,
            description: 'The number of items to skip before starting ' \
            'to collect the result set',
            schema: { type: :integer, minimum: 1, default: 1 }
end

def pagination_params_v2
  parameter name: :limit, in: :query, required: false,
            description: 'Number of items to return per page',
            schema: { type: :number, maximum: 100, minimum: 1, default: 10 }
  parameter name: :offset, in: :query, required: false,
            description: 'Offset of first item of paginated response',
            schema: { type: :integer, minimum: 0, default: 0 }
end

def search_params
  parameter name: :search, in: :query, required: false,
            description: 'Query string compliant with scoped_search ' \
            'query language: ' \
            'https://github.com/wvanbergen/scoped_search/wiki/Query-language',
            schema: { type: :string }
end

def search_params_v2(model = nil)
  parameter name: :filter, in: :query, required: false,
            description: 'Query string to filter items by their attributes. ' \
              'Compliant with <a href="https://github.com/wvanbergen/scoped_search/wiki/Query-language" ' \
              'target="_blank" title="github.com/wvanbergen/scoped_search">scoped_search query language</a>. ' \
              'However, only `=` or `!=` (resp. `<>`) operators are supported.<br><br>' \
              "#{model.name.split('::').second.gsub(/([A-Z])/) { " #{Regexp.last_match(1)}" }.strip.pluralize} " \
              'are searchable using attributes ' \
              "#{model.scoped_search.fields.keys.map { |k| "`#{k}`" }.to_sentence}" \
              '<br><br>(e.g.: `(version=0.1.47 AND os_major_verision=8)`)',
            schema: { type: :string }
end

def tags_params
  parameter name: :tags, in: :query, required: false,
            description: 'A string or an array of tags to narrow down the results against. ' \
            'The namespace, key and value are concatenated using `/` and `=` symbols. ' \
            'In case the values contain symbols used for separators, `/` is replaced with `%2F`, ' \
            '`=` is replaced with `%3D`.<br><br>' \
            'e.g.: `namespace/key=value`, `insights-client/selinux-config=SELINUX%3Denforcing`',
            schema: { type: :array, items: { type: 'string' } }
end

def sort_params(model = nil)
  parameter name: :sort_by, in: :query, required: false,
            description: 'A string or an array of fields with an optional direction ' \
             '(:asc or :desc) to sort the results.',
            schema: {
              oneOf: [{ type: :array, items: { type: 'string' } }, { type: :string }],
              items: { enum: sort_combinations(model) }
            }
end

def sort_params_v2(model = nil)
  parameter name: :sort_by, in: :query, required: false,
            description: 'Attribute and direction to sort the items by. ' \
              'Represented by an array of fields with an optional direction ' \
              '(`<key>:asc` or `<key>:desc`).<br><br>' \
              'If no direction is selected, `<key>:asc` is used by default.',
            schema: {
              type: :array,
              items: { enum: sort_combinations(model) }
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

def v2_collection_schema(label)
  schema(type: :object,
         properties: {
           meta: ref_schema('metadata'),
           links: ref_schema('links'),
           data: {
             type: :array,
             items: { properties: { schema: ref_schema(label) } }
           }
         })
end

def v2_item_schema(label)
  schema(type: :object,
         properties: {
           data: {
             type: :object,
             properties: {
               schema: ref_schema(label)
             }
           }
         })
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

def v2_auth_header
  parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string, description: 'For internal use only' }
end
