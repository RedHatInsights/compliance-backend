# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'minitest/reporters'
require 'minitest/mock'
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
