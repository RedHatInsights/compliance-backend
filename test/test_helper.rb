# frozen_string_literal: true

require 'rails'

unless Rails.env.production?
  require 'simplecov'
  SimpleCov.start do
    add_filter 'config'
    add_filter 'db'
    add_filter 'spec'
    add_filter 'test'

    add_group 'Consumers', 'app/consumers'
    add_group 'Controllers', 'app/controllers'
    add_group 'GraphQL', 'app/graphql'
    add_group 'Jobs', 'app/jobs'
    add_group 'Models', 'app/models'
    add_group 'Policies', 'app/policies'
    add_group 'Serializers', 'app/serializers'
    add_group 'Services', 'app/services'
  end

  if ENV['GITHUB_ACTIONS']
    require 'simplecov-cobertura'
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  end

  ENV['RAILS_ENV'] ||= 'test'

  require_relative '../config/environment'
  require 'rails/test_help'

  require 'minitest/reporters'
  require 'minitest/mock'
  require 'mocha/minitest'

  Minitest::Reporters.use!(
    [
      Minitest::Reporters::JUnitReporter.new,
      Minitest::Reporters::ProgressReporter.new
    ],
    ENV,
    Minitest.backtrace_filter
  )

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :minitest_5
      with.library :rails
    end
  end

  module ActiveSupport
    class TestCase
      self.use_transactional_tests = true

      parallelize

      parallelize_setup do |worker|
        SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"

        ActiveRecord::Base.connection.execute(
          IO.read('db/cyndi_setup_test.sql')
        )
      end

      parallelize_teardown do
        SimpleCov.result
      end

      def assert_audited_success(*msg)
        Rails.logger.expects(:audit_success).with(includes(*msg))
      end

      def assert_audited_fail(*msg)
        Rails.logger.expects(:audit_fail).with(includes(*msg))
      end

      def assert_equal_sets(arr1, arr2)
        assert_equal Set.new(arr1), Set.new(arr2)
      end

      def stub_supported_ssg(hosts, benchmark_versions = nil)
        supported_ssgs = []

        benchmark_versions ||= test_benchmark_versions

        benchmark_versions.each do |bmv|
          new_supported_ssgs = test_supported_ssgs(hosts, bmv)
          supported_ssgs += new_supported_ssgs
          # Stubbing by_ssg_version because some tests were failing due to
          # the conditional assignment with the instance variable
          SupportedSsg.stubs(:by_ssg_version).returns(bmv => new_supported_ssgs)
        end
        SupportedSsg.stubs(:all).returns(supported_ssgs)
        SupportedSsg.stubs(:revision).returns('2022-04-20')
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
        # Remove any previous mocks
        Rbac::API_CLIENT.unstub(:get_principal_access)
        Rbac::API_CLIENT.stubs(:get_principal_access).returns(role)
      end
      # rubocop:enable Metrics/MethodLength
    end
  end

  module ActionDispatch
    class IntegrationTest
      def json_body
        response.parsed_body
      end

      def params(data)
        { data: data }
      end

      def parsed_data
        json_body.dig('data')
      end
    end
  end

  private

  def test_supported_ssgs(hosts, bmv)
    hosts.map do |host|
      SupportedSsg.new(
        os_major_version: host.os_major_version.to_s,
        os_minor_version: host.os_minor_version.to_s,
        version: bmv
      )
    end
  end

  def test_benchmark_versions
    bm1 = FactoryBot.create(
      :benchmark, version: '0.2.50',
                  os_major_version: '7'
    )

    bm2 = FactoryBot.create(
      :benchmark, version: '0.1.51',
                  os_major_version: '7'
    )
    [bm1.version, bm2.version]
  end
end
