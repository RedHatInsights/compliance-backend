# frozen_string_literal: true

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

  module ActiveSupport
    class TestCase
      parallelize(workers: 4)
    end
  end

  ENV['RAILS_ENV'] ||= 'test'
  require_relative '../config/environment'
  require 'rails/test_help'

  require 'minitest/reporters'
  require 'minitest/mock'
  require 'mocha/minitest'

  Minitest::Reporters.use!(
    Minitest::Reporters::ProgressReporter.new,
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
      fixtures :all
      self.use_transactional_tests = true
    end
  end

  module ActionDispatch
    class IntegrationTest
      def json_body
        JSON.parse(response.body)
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
