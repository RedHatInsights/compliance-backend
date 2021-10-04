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

  if ENV['CODECOV_TOKEN']
    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
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

      setup do
        audit_log_capturing
      end

      def audit_log_capturing
        audit_logger = Rails.application.config.audit_logger
        @audit_log = StringIO.new
        audit_logger.reopen(@audit_log)
      end

      def assert_audited(msg)
        msg_json = ::JSON.generate(msg)[1..-2]

        assert_includes @audit_log.string,
                        msg_json,
                        "Message '#{msg}' not audited"
      end

      def assert_equal_sets(arr1, arr2)
        assert_equal Set.new(arr1), Set.new(arr2)
      end
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
end
