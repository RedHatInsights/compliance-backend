# frozen_string_literal: true

unless Rails.env.production?
  require 'simplecov'
  SimpleCov.start 'rails' do
    # don't test the schema!
    # https://github.com/rmosolgo/graphql-ruby/blob/master/guides/schema/
    # testing.md#dont-test-the-schema
    add_filter 'db/schema.rb'
    # these just contain the description of the attributes of the
    # API responses, no code (https://github.com/Netflix/fast_jsonapi)
    add_filter 'app/serializers'
    # empty class that has to be there for prometheus integration
    add_filter 'lib/'
    add_group 'Consumers', 'app/consumers'
    add_group 'GraphQL', 'app/graphql'
    add_group 'Policies', 'app/policies'
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
    end
  end
end
