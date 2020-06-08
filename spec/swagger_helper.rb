# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require './spec/api/v1/openapi'
require './spec/api/v1/schemas/util'

include Api::V1::Schemas::Util # rubocop:disable Style/MixinUsage

RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'

  config.before(:each) do
    stub_request(:get, /#{Settings.rbac_url}/)
      .to_return(status: 200,
                 body: { 'data': [{ 'permission': 'compliance:*:*' }] }.to_json)
  end

  config.swagger_docs = {
    'v1/openapi.json' => Api::V1::Openapi.doc
  }
end

def autogenerate_examples(example)
  example.metadata[:response][:examples] = {
    'application/vnd.api+json' => JSON.parse(response.body,
                                             symbolize_names: true)
  }
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
      'account_number': account&.account_number || '1234',
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
  parameter name: :include, in: :query, type: :string, required: false,
            schema: { type: :string },
            description: 'A comma seperated list of resources to include in '\
                         'the response'
end

def pagination_params
  parameter name: :limit, in: :query, required: false, type: :integer,
            description: 'The number of items to return',
            schema: { type: :integer, maximum: 100, minimum: 1, default: 10 }
  parameter name: :offset, in: :query, required: false, type: :integer,
            description: 'The number of items to skip before starting '\
            'to collect the result set',
            schema: { type: :integer, minimum: 1, default: 1 }
end

def search_params
  parameter name: :search, in: :query, required: false, type: :string,
            description: 'Query string compliant with scoped_search '\
            'query language: '\
            'https://github.com/wvanbergen/scoped_search/wiki/Query-language',
            schema: { type: :string, default: '' }
end

def content_types
  consumes 'application/vnd.api+json'
  produces 'application/vnd.api+json'
end

def auth_header
  parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string }
end
