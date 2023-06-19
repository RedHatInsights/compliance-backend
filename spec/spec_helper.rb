# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

if ENV['GITHUB_ACTIONS']
  require 'simplecov-cobertura'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include FactoryBot::Syntax::Methods
end

# rubocop:disable Metrics/MethodLength
def stub_rbac_permissions(*arr, **hsh)
  permissions = arr + hsh.to_a
  role_permissions = permissions.map do |permission, rd = []|
    RBACApiClient::Access.new(
      permission: permission,
      resource_definitions: rd
    )
  end
  role = RBACApiClient::AccessPagination.new(data: role_permissions)
  allow(Rbac::API_CLIENT).to receive(:get_principal_access).and_return(role)
end
# rubocop:enable Metrics/MethodLength

def response_body_data
  response.parsed_body['data']
end
