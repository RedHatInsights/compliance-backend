# frozen_string_literal: true

if Rails.env.test?
  require 'karafka/testing/rspec/helpers'
  require 'simplecov'

  if ENV['GITHUB_ACTIONS']
    require 'simplecov-cobertura'
    SimpleCov.command_name 'spec'
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  end

  RSpec.configure do |config|
    config.expect_with :rspec do |expectations|
      expectations.include_chain_clauses_in_custom_matcher_descriptions = true
      expectations.max_formatted_output_length = nil
    end

    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = true
    end

    config.shared_context_metadata_behavior = :apply_to_host_groups

    config.include FactoryBot::Syntax::Methods
    config.include Karafka::Testing::RSpec::Helpers
  end

  # rubocop:disable Layout/LineLength
  # FIXME: Remove this once we move away from v1 tests
  # Needed due to Karafka not expecting Mocha and Rspec mocking to be used at the same time
  # https://github.com/karafka/karafka-testing/blob/2c22020b9befb1e583eba2e75a857a42ea45c389/lib/karafka/testing/rspec/helpers.rb#L49-L53
  # rubocop:enable Layout/LineLength
  Object.send(:remove_const, :Mocha)

  # rubocop:disable Metrics/MethodLength
  def stub_rbac_permissions(*arr, **hsh)
    permissions = arr + hsh.to_a
    role_permissions = permissions.map do |permission, rds = []|
      RBACApiClient::Access.new(
        permission: permission,
        resource_definitions: rds.map do |rd|
          RBACApiClient::ResourceDefinition.new(
            attribute_filter: RBACApiClient::ResourceDefinitionFilter.new(rd[:attribute_filter])
          )
        end
      )
    end
    role = RBACApiClient::AccessPagination.new(data: role_permissions)
    allow(Rbac::API_CLIENT).to receive(:get_principal_access).and_return(role)
  end
  # rubocop:enable Metrics/MethodLength

  # Wrapper for scalar values in `extra_params` that need to be omitted from `passable_params`
  def pw(item)
    Struct.new(:item) do
      def value
        item
      end
    end.new(item)
  end

  # Do not pass instances of `ActiveRecord` or scalar values wrapped with `pw()` to the URL parameters
  def reject_nonscalar(extra_params)
    extra_params.reject { |_, ep| ep.is_a?(ActiveRecord::Base) || ep.is_a?(Struct) }
  end

  # Assembles an object to be passed into factory
  # - adds url params into an object based on yaml entity definition in sorting and searching specs
  # - if object with method call is passed, it parses object and method into m[1] and m[3] and executes
  def factory_params(item, extra_params)
    item.each_with_object({}) do |(key, value), obj|
      obj[key] = value
      value.is_a?(String) && value.match(/^\$\{([a-zA-Z_]+[a-zA-Z_0-9]*)(\.([a-zA-Z_]+))?\}$/) do |m|
        obj_or_attr = extra_params[m[1].to_sym]
        obj_or_attr = obj_or_attr.value if obj_or_attr.is_a?(Struct)
        obj[key] = m[3] ? obj_or_attr.try(m[3].to_sym) : obj_or_attr
      end
    end
  end

  # Assembles a query using interpolations feeded by extra_params (see `factory_params` above)
  def query_params(value, extra_params)
    value.gsub(/\$\{([a-zA-Z_]+[a-zA-Z_0-9]*)(\.([a-zA-Z_]+))?\}/) do |_match|
      obj_or_attr = extra_params[Regexp.last_match[1].to_sym]
      obj_or_attr = obj_or_attr.value if obj_or_attr.is_a?(Struct)
      Regexp.last_match[3] ? obj_or_attr.try(Regexp.last_match[3].to_sym) : obj_or_attr
    end
  end

  def response_body_data
    response.parsed_body['data']
  end
end
